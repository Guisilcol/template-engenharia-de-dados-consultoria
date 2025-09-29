#!/bin/bash

# Encerra o script se qualquer comando falhar
set -e

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

echo ">>> Deploy concluído com sucesso!"
