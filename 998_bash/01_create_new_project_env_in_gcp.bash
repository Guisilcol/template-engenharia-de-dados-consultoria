#!/bin/bash

# Função para exibir ajuda
show_help() {
  cat << EOF
USAGE:
  $0 [OPTIONS] <BILLING_ACCOUNT_ID> [ORGANIZATION_ID] <BASE_PROJECT_NAME>

DESCRIPTION:
  Script para criação automática de projetos no Google Cloud Platform.
  Cria projetos para os ambientes: dev e prod.

ARGUMENTS:
  BILLING_ACCOUNT_ID    ID da conta de faturamento (formato: XXXXXX-XXXXXX-XXXXXX)
  ORGANIZATION_ID       ID da organização no GCP (OPCIONAL - use "none" para pular)
  BASE_PROJECT_NAME     Nome base para os projetos (será usado como prefixo)

OPTIONS:
  --help, -h           Exibe esta mensagem de ajuda

EXAMPLES:
  Com organização:
    $0 0X0X0X-0X0X0X-0X0X0X 123456789012 meu-app
  
  Sem organização (conta pessoal):
    $0 0X0X0X-0X0X0X-0X0X0X none meu-app
  
  Apenas 2 parâmetros (billing + project name):
    $0 0X0X0X-0X0X0X-0X0X0X meu-app
  
  Ajuda:
    $0 --help

REQUIREMENTS:
  - Google Cloud CLI (gcloud) deve estar instalado e configurado
  - Permissões adequadas para criar projetos
EOF
}

# Função para verificar se o gcloud está instalado
check_gcloud() {
  if ! command -v gcloud &> /dev/null; then
    echo "ERRO: O programa 'gcloud' não está instalado."
    echo "Por favor, instale o Google Cloud CLI antes de executar este script."
    echo "Instruções: https://cloud.google.com/sdk/docs/install"
    exit 1
  fi
  
  echo "✓ Google Cloud CLI encontrado: $(gcloud --version | head -n1)"
}

# Função para verificar se o usuário está autenticado no gcloud
check_gcloud_auth() {
  echo "Verificando autenticação no Google Cloud..."
  
  # Verifica se há uma conta ativa
  ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
  
  if [[ -z "$ACTIVE_ACCOUNT" ]] || [[ "$ACTIVE_ACCOUNT" == "(unset)" ]]; then
    echo "ERRO: Nenhuma conta está autenticada no gcloud."
    echo "Por favor, execute 'gcloud auth login' para fazer login."
    exit 1
  fi
  
  # Testa se as credenciais são válidas fazendo uma chamada simples
  if ! gcloud projects list --limit=1 &>/dev/null; then
    echo "ERRO: Credenciais do gcloud expiradas ou inválidas."
    echo "Por favor, execute 'gcloud auth login' para renovar as credenciais."
    exit 1
  fi
  
  echo "✓ Autenticado como: $ACTIVE_ACCOUNT"
}

# Array para armazenar projetos criados (para rollback)
CREATED_PROJECTS=()

# Função para fazer rollback (deletar projetos criados)
rollback_projects() {
  if [[ ${#CREATED_PROJECTS[@]} -eq 0 ]]; then
    echo "Nenhum projeto foi criado. Nada para desfazer."
    return
  fi
  
  echo ""
  echo "=============================================="
  echo "INICIANDO ROLLBACK - REMOVENDO PROJETOS CRIADOS"
  echo "=============================================="
  
  for PROJECT_ID in "${CREATED_PROJECTS[@]}"; do
    echo "Removendo projeto: $PROJECT_ID"
    
    # Tentar deletar o projeto
    if gcloud projects delete "$PROJECT_ID" --quiet 2>/dev/null; then
      echo "✓ Projeto $PROJECT_ID removido com sucesso"
    else
      echo "✗ Falha ao remover projeto $PROJECT_ID (pode precisar ser removido manualmente)"
    fi
  done
  
  echo "=============================================="
  echo "ROLLBACK CONCLUÍDO"
  echo "=============================================="
}

# Função para limpar em caso de erro
cleanup_on_error() {
  local exit_code=$1
  echo ""
  echo "=============================================="
  echo "ERRO DETECTADO - INICIANDO LIMPEZA"
  echo "=============================================="
  rollback_projects
  exit $exit_code
}

# Configurar trap para limpeza em caso de erro ou interrupção
trap 'cleanup_on_error $?' ERR EXIT

# Verificar parâmetros de entrada
if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# Aceita 2 parâmetros (billing + project) ou 3 parâmetros (billing + org + project)
if [[ $# -lt 2 ]] || [[ $# -gt 3 ]]; then
  echo "ERRO: Número incorreto de parâmetros."
  echo "Esperado: 2 ou 3 parâmetros"
  echo "  - 2 parâmetros: BILLING_ACCOUNT_ID BASE_PROJECT_NAME"
  echo "  - 3 parâmetros: BILLING_ACCOUNT_ID ORGANIZATION_ID BASE_PROJECT_NAME"
  echo "Recebido: $# parâmetros"
  echo ""
  echo "Use '$0 --help' para ver instruções de uso."
  exit 1
fi

# Verificar se o gcloud está instalado
check_gcloud

# Verificar se o usuário está autenticado
check_gcloud_auth

# --- CONFIGURAÇÕES ---
BILLING_ACCOUNT_ID="$1"

# Detectar se temos 2 ou 3 parâmetros
if [[ $# -eq 2 ]]; then
  # 2 parâmetros: billing + project (sem organização)
  ORGANIZATION_ID=""
  BASE_PROJECT_NAME="$2"
elif [[ $# -eq 3 ]]; then
  # 3 parâmetros: billing + org + project
  ORGANIZATION_ID="$2"
  BASE_PROJECT_NAME="$3"
  
  # Se organization foi especificada como "none", tratar como vazio
  if [[ "$ORGANIZATION_ID" == "none" ]] || [[ "$ORGANIZATION_ID" == "None" ]] || [[ "$ORGANIZATION_ID" == "NONE" ]]; then
    ORGANIZATION_ID=""
  fi
fi

# Validar formato do BILLING_ACCOUNT_ID (básico)
if [[ ! "$BILLING_ACCOUNT_ID" =~ ^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$ ]]; then
  echo "AVISO: O formato do BILLING_ACCOUNT_ID pode estar incorreto."
  echo "Formato esperado: XXXXXX-XXXXXX-XXXXXX (onde X são números ou letras maiúsculas)"
  echo "Valor fornecido: $BILLING_ACCOUNT_ID"
  echo ""
fi

# Validar se ORGANIZATION_ID é numérico (apenas se fornecido)
if [[ -n "$ORGANIZATION_ID" ]] && [[ ! "$ORGANIZATION_ID" =~ ^[0-9]+$ ]]; then
  echo "ERRO: ORGANIZATION_ID deve conter apenas números."
  echo "Valor fornecido: $ORGANIZATION_ID"
  exit 1
fi

echo "==================================================="
echo "CONFIGURAÇÕES DO SCRIPT:"
echo "==================================================="
echo "Billing Account ID: $BILLING_ACCOUNT_ID"
if [[ -n "$ORGANIZATION_ID" ]]; then
  echo "Organization ID: $ORGANIZATION_ID"
else
  echo "Organization ID: (não especificada - projetos serão criados sem organização)"
fi
echo "Base Project Name: $BASE_PROJECT_NAME"
echo "==================================================="
echo ""

# Lista de ambientes
ENVIRONMENTS=("dev" "prod")

# Habilitar modo de erro (para que o script pare em qualquer erro)
set -e

echo "Iniciando criação de projetos..."
echo ""

# --- EXECUÇÃO ATÔMICA ---
for ENV in "${ENVIRONMENTS[@]}"
do
  # Gera um sufixo aleatório para garantir um ID único
  RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)
  PROJECT_ID="${BASE_PROJECT_NAME}-${ENV}-${RANDOM_SUFFIX}"
  PROJECT_NAME="${BASE_PROJECT_NAME}-${ENV}"

  echo "-----------------------------------------------------"
  echo "Criando projeto: ${PROJECT_NAME} com ID: ${PROJECT_ID}"
  echo "-----------------------------------------------------"

  # 1. Cria o projeto
  echo "► Passo 1/3: Criando projeto..."
  if [[ -n "$ORGANIZATION_ID" ]]; then
    echo "  Criando projeto com organização ID: $ORGANIZATION_ID"
    if ! gcloud projects create ${PROJECT_ID} --name="${PROJECT_NAME}" --organization=${ORGANIZATION_ID}; then
      echo "✗ ERRO: Falha ao criar projeto $PROJECT_ID"
      exit 1
    fi
  else
    echo "  Criando projeto sem organização (conta pessoal/sem org)"
    if ! gcloud projects create ${PROJECT_ID} --name="${PROJECT_NAME}"; then
      echo "✗ ERRO: Falha ao criar projeto $PROJECT_ID"
      exit 1
    fi
  fi
  
  # Adicionar ao array de projetos criados para possível rollback
  CREATED_PROJECTS+=("$PROJECT_ID")
  echo "✓ Projeto $PROJECT_ID criado com sucesso"

  # 2. Vincula a conta de faturamento ao projeto
  echo "► Passo 2/3: Vinculando conta de faturamento..."
  if ! gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID}; then
    echo "✗ ERRO: Falha ao vincular billing account ao projeto $PROJECT_ID"
    exit 1
  fi
  echo "✓ Billing account vinculada com sucesso"

  # 3. Ativa uma API no projeto (ex: Compute Engine)
  echo "► Passo 3/3: Ativando APIs necessárias..."
  if ! gcloud services enable compute.googleapis.com --project=${PROJECT_ID}; then
    echo "✗ ERRO: Falha ao ativar APIs no projeto $PROJECT_ID"
    exit 1
  fi
  echo "✓ APIs ativadas com sucesso"

  echo "✓ Projeto ${PROJECT_ID} criado e configurado com sucesso!"
  echo ""
done

# Se chegou até aqui, todos os projetos foram criados com sucesso
# Desabilitar trap de limpeza para não fazer rollback
trap - ERR EXIT

echo "=============================================="
echo "✓ TODOS OS PROJETOS CRIADOS COM SUCESSO!"
echo "=============================================="
echo "Projetos criados:"
for PROJECT_ID in "${CREATED_PROJECTS[@]}"; do
  echo "  - $PROJECT_ID"
done
echo "=============================================="