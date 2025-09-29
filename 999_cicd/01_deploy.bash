#!/bin/bash

# Script para fazer deploy nos ambientes.
# Autor: Guilherme dos Santos Magalhães
# Data: 2024-06-29

# Versão 1.0
#	- Criação inicial do script

# Encerra o script se qualquer comando falhar
set -e

# Verificar se git e terraform estão instalados
if ! command -v git &>/dev/null; then
	echo "Erro: git não está instalado. Por favor, instale o git e tente novamente."
	exit 1
fi
echo ">>> Git... OK"

if ! command -v terraform &>/dev/null; then
	echo "Erro: terraform não está instalado. Por favor, instale o terraform e tente novamente."
	exit 1
fi
echo ">>> Terraform... OK"

# 1. Receber o nome da branch e do ambiente
if [ "$#" -ne 2 ]; then
	echo "Uso: $0 <nome-da-branch> <ambiente>"
	exit 1
fi

BRANCH_NAME=$1
ENVIRONMENT=$2
INFRA_DIR="000_infrastructure"
BACKEND_CONFIG_FILE="${INFRA_DIR}/inventories/backend/${ENVIRONMENT}.conf"
TFVARS_FILE="${INFRA_DIR}/inventories/tfvars/${ENVIRONMENT}.tfvars"

echo ">>> Iniciando deploy da branch '${BRANCH_NAME}' para o ambiente '${ENVIRONMENT}'"

# 2. Verificar se o nome do ambiente existe
echo ">>> Verificando arquivo de configuração do ambiente..."
if [ ! -f "${BACKEND_CONFIG_FILE}" ]; then
	echo "Erro: O ambiente '${ENVIRONMENT}' é inválido. Arquivo '${BACKEND_CONFIG_FILE}' não encontrado."
	exit 1
fi
echo "Ambiente '${ENVIRONMENT}' verificado com sucesso."

# 3. Verificar se o nome da branch informada existe
echo ">>> Verificando se a branch '${BRANCH_NAME}' existe no repositório remoto..."
if ! git ls-remote --exit-code --heads origin "${BRANCH_NAME}"; then
	echo "Erro: A branch '${BRANCH_NAME}' não foi encontrada no repositório remoto 'origin'."
	exit 1
fi
echo "Branch '${BRANCH_NAME}' encontrada."

# 4. Baixar o conteudo da branch em uma pasta temporária
TMP_DIR=$(mktemp -d -t deploy-XXXXXX)
# Garante que o diretório temporário seja removido ao final do script
trap 'rm -rf "$TMP_DIR"' EXIT

echo ">>> Baixando conteúdo da branch '${BRANCH_NAME}' para o diretório temporário '${TMP_DIR}'..."
git archive "${BRANCH_NAME}" | tar -x -C "${TMP_DIR}"
echo "Download concluído."

# 5. Usar a pasta baixada para fazer deploy
DEPLOY_DIR="${TMP_DIR}/${INFRA_DIR}"

if [ ! -d "${DEPLOY_DIR}" ]; then
	echo "Erro: O diretório de infraestrutura '${INFRA_DIR}' não foi encontrado no conteúdo da branch."
	exit 1
fi

cd "${DEPLOY_DIR}"
echo ">>> Entrando no diretório: $(pwd)"

echo ">>> Executando terraform init..."
terraform init -backend-config="./inventories/backend/${ENVIRONMENT}.conf"

echo ">>> Executando terraform apply..."
terraform apply -var-file="./inventories/tfvars/${ENVIRONMENT}.tfvars" -auto-approve

echo ">>> Preparando build da imagem Docker para ser usada no Cloud Run..."

# 6. Extrair informações do ambiente para o build da imagem
echo ">>> Extraindo PROJECT_ID e REGION do arquivo .tfvars..."
PROJECT_ID=$(grep -oP 'project_id\s*=\s*"\K[^"]+' "./inventories/tfvars/${ENVIRONMENT}.tfvars")
REGION=$(grep -oP 'region\s*=\s*"\K[^"]+' "./inventories/tfvars/${ENVIRONMENT}.tfvars")

if [ -z "${PROJECT_ID}" ] || [ -z "${REGION}" ]; then
    echo "Erro: Não foi possível extrair PROJECT_ID e/ou REGION do arquivo ${TFVARS_FILE}."
    exit 1
fi

echo "PROJECT_ID: ${PROJECT_ID}"
echo "REGION: ${REGION}"

# 7. Build e Push da imagem Docker
REPO_NAME="docker-repo" # Nome do repositório no Artifact Registry (deve existir no projeto)
IMAGE_NAME="sample-job" # Nome da imagem
IMAGE_TAG="latest" # Tag da imagem
IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
DOCKERFILE_CONTEXT="../001_jobs"

echo ">>> Verificando dependências do Docker e autenticação do gcloud..."
if ! command -v docker &>/dev/null; then
	echo "Erro: docker não está instalado. Por favor, instale o Docker e tente novamente."
	exit 1
fi

# Verifica se o usuário atual consegue falar com o daemon sem sudo
if ! docker info &>/dev/null; then
	echo "Erro: não foi possível acessar o daemon do Docker."
	echo "Dica: adicione seu usuário ao grupo 'docker' e reinicie a sessão: sudo usermod -aG docker $USER"
	exit 1
fi

# Verifica autenticação do gcloud
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" || true)
if [ -z "${ACTIVE_ACCOUNT}" ]; then
	echo "Erro: gcloud não está autenticado. Execute 'gcloud auth login' ou 'gcloud auth activate-service-account' e tente novamente."
	exit 1
fi

echo ">>> Configurando autenticação Docker para o Artifact Registry (usando conta ${ACTIVE_ACCOUNT})..."
gcloud config set project "${PROJECT_ID}" 1>/dev/null
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo ">>> Buildando a imagem Docker..."
docker build -t "${IMAGE_URI}" "${DOCKERFILE_CONTEXT}"

echo ">>> Enviando a imagem para o Artifact Registry..."
docker push "${IMAGE_URI}"

echo ">>> Imagem enviada com sucesso para ${IMAGE_URI}"
