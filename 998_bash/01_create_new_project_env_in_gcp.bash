#!/bin/bash

############################
# Função para exibir ajuda #
############################

show_help() {
  cat << EOF
USAGE:
  $0 [OPTIONS] [BILLING_ACCOUNT_ID] [ORGANIZATION_ID] <BASE_PROJECT_NAME>
  $0 --auto-billing [ORGANIZATION_ID] <BASE_PROJECT_NAME>

DESCRIPTION:
  Script para criação automática de projetos no Google Cloud Platform.
  Cria projetos para os ambientes: dev e prod.

ARGUMENTS:
  BILLING_ACCOUNT_ID    ID da conta de faturamento (formato: XXXXXX-XXXXXX-XXXXXX)
                        Se não fornecido, será detectado automaticamente
  ORGANIZATION_ID       ID da organização no GCP (OPCIONAL - use "none" para pular)
  BASE_PROJECT_NAME     Nome base para os projetos (será usado como prefixo)

OPTIONS:
  --help, -h           Exibe esta mensagem de ajuda
  --auto-billing       Detecta automaticamente a conta de billing
  --list-billing       Lista contas de billing disponíveis e sai

EXAMPLES:
  Detecção automática de billing:
    $0 --auto-billing meu-app
    $0 --auto-billing none meu-app
    $0 --auto-billing 123456789012 meu-app
  
  Com billing especificado:
    $0 0X0X0X-0X0X0X-0X0X0X 123456789012 meu-app
  
  Sem organização (conta pessoal):
    $0 0X0X0X-0X0X0X-0X0X0X none meu-app
  
  Apenas billing + project name:
    $0 0X0X0X-0X0X0X-0X0X0X meu-app
  
  Listar contas de billing:
    $0 --list-billing
  
  Ajuda:
    $0 --help

REQUIREMENTS:
  - Google Cloud CLI (gcloud) deve estar instalado e configurado
  - Permissões adequadas para criar projetos e acessar billing accounts
EOF
}

####################################################
# Função para verificar se o gcloud está instalado #
####################################################

check_gcloud() {
  if ! command -v gcloud &> /dev/null; then
    echo "ERRO: O programa 'gcloud' não está instalado."
    echo "Por favor, instale o Google Cloud CLI antes de executar este script."
    echo "Instruções: https://cloud.google.com/sdk/docs/install"
    exit 1
  fi
  
  echo "✓ Google Cloud CLI encontrado: $(gcloud --version | head -n1)"
}

#################################################################
# Função para verificar se o usuário está autenticado no gcloud #
#################################################################

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

###########################################################
# Função para detectar automaticamente a conta de billing #
###########################################################

get_billing_account() {
  echo "Detectando contas de faturamento disponíveis..." >&2
  
  # Lista todas as contas de billing ativas
  local BILLING_ACCOUNTS
  BILLING_ACCOUNTS=$(gcloud beta billing accounts list --filter="open=true" --format="value(name)" 2>/dev/null)
  
  if [[ -z "$BILLING_ACCOUNTS" ]]; then
    echo "ERRO: Nenhuma conta de faturamento ativa encontrada." >&2
    echo "Verifique se você tem permissões para acessar contas de faturamento." >&2
    return 1
  fi
  
  # Converte a lista em um array
  local ACCOUNTS_ARRAY=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      # Extrai apenas o ID da conta (formato: billingAccounts/XXXXXX-XXXXXX-XXXXXX)
      local ACCOUNT_ID=$(echo "$line" | sed 's|billingAccounts/||')
      ACCOUNTS_ARRAY+=("$ACCOUNT_ID")
    fi
  done <<< "$BILLING_ACCOUNTS"
  
  # Se há apenas uma conta, usa ela automaticamente
  if [[ ${#ACCOUNTS_ARRAY[@]} -eq 1 ]]; then
    echo "✓ Conta de faturamento detectada automaticamente: ${ACCOUNTS_ARRAY[0]}" >&2
    echo "${ACCOUNTS_ARRAY[0]}"
    return 0
  fi
  
  # Se há múltiplas contas, lista para o usuário escolher
  echo "Múltiplas contas de faturamento encontradas:" >&2
  for i in "${!ACCOUNTS_ARRAY[@]}"; do
    echo "  $((i+1)). ${ACCOUNTS_ARRAY[i]}" >&2
  done
  
  echo "" >&2
  echo "Por favor, execute o script especificando uma das contas acima:" >&2
  echo "  $0 <BILLING_ACCOUNT_ID> [ORGANIZATION_ID] <BASE_PROJECT_NAME>" >&2
  echo "" >&2
  echo "Ou use o parâmetro --auto-billing para usar a primeira conta automaticamente." >&2
  
  return 1
}

#######################################################
# Função para gerar nomes dos projetos que serão criados #
#######################################################

generate_project_names() {
  local BASE_PROJECT_NAME="$1"
  local ENVIRONMENTS=("dev" "prod")
  local PROJECT_NAMES=()
  
  for ENV in "${ENVIRONMENTS[@]}"; do
    # Gera um sufixo aleatório para simular o que será usado
    local RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)
    local PROJECT_ID="${BASE_PROJECT_NAME}-${ENV}-${RANDOM_SUFFIX}"
    PROJECT_NAMES+=("$PROJECT_ID")
  done
  
  printf '%s\n' "${PROJECT_NAMES[@]}"
}

#########################################################
# Função para confirmar a criação dos projetos #
#########################################################

confirm_project_creation() {
  local BILLING_ACCOUNT_ID="$1"
  local ORGANIZATION_ID="$2"
  local BASE_PROJECT_NAME="$3"
  local AUTO_BILLING="$4"
  
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║                    RESUMO DA OPERAÇÃO                           ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "📋 O que será criado:"
  echo "   • 2 projetos no Google Cloud Platform"
  echo "   • Ambientes: dev e prod"
  echo ""
  echo "🏷️  Nomes dos projetos (aproximados):"
  local SAMPLE_NAMES=($(generate_project_names "$BASE_PROJECT_NAME"))
  for name in "${SAMPLE_NAMES[@]}"; do
    echo "   • $name"
  done
  echo "   (Os sufixos aleatórios finais podem variar)"
  echo ""
  echo "💳 Conta de faturamento:"
  echo "   • ID: $BILLING_ACCOUNT_ID"
  if [[ "$AUTO_BILLING" == true ]]; then
    echo "   • Fonte: detectada automaticamente"
  else
    echo "   • Fonte: especificada manualmente"
  fi
  echo ""
  echo "🏢 Organização:"
  if [[ -n "$ORGANIZATION_ID" ]]; then
    echo "   • ID: $ORGANIZATION_ID"
  else
    echo "   • Nenhuma (projetos serão criados em conta pessoal)"
  fi
  echo ""
  echo "⚙️  Configurações que serão aplicadas:"
  echo "   • Conta de faturamento será vinculada a ambos os projetos"
  echo "   • API do Compute Engine será ativada"
  echo "   • Projetos serão configurados e prontos para uso"
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║                           ATENÇÃO                               ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo "⚠️  Esta operação irá:"
  echo "   • Consumir recursos da sua conta de faturamento"
  echo "   • Criar projetos permanentes no GCP"
  echo "   • Ativar APIs que podem gerar custos"
  echo ""
  
  # Loop para confirmação
  while true; do
    echo -n "🤔 Deseja continuar com a criação dos projetos? (s/N): "
    read -r CONFIRM
    
    case "$CONFIRM" in
      [Ss]|[Ss][Ii][Mm]|[Yy]|[Yy][Ee][Ss])
        echo ""
        echo "✅ Confirmado! Iniciando criação dos projetos..."
        return 0
        ;;
      [Nn]|[Nn][Aa][Oo]|[Nn][Oo]|"")
        echo ""
        echo "❌ Operação cancelada pelo usuário."
        echo "Nenhum projeto foi criado."
        exit 0
        ;;
      *)
        echo "❓ Resposta inválida. Digite 's' para SIM ou 'n' para NÃO."
        ;;
    esac
  done
}

#########################################################
# Array para armazenar projetos criados (para rollback) #
#########################################################

CREATED_PROJECTS=()

#########################################################
# Função para fazer rollback (deletar projetos criados) #
##########################################################

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

######################################
# Função para limpar em caso de erro #
######################################
cleanup_on_error() {
  local exit_code=$1
  echo ""
  echo "=============================================="
  echo "ERRO DETECTADO - INICIANDO LIMPEZA"
  echo "=============================================="
  rollback_projects
  exit $exit_code
}

################################
# Função para criar um projeto #
################################

create_project() {
  local ENV=$1
  local ORGANIZATION_ID=$2
  local BILLING_ACCOUNT_ID=$3
  local BASE_PROJECT_NAME=$4
  
  # Gera um sufixo aleatório para garantir um ID único
  local RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)
  local PROJECT_ID="${BASE_PROJECT_NAME}-${ENV}-${RANDOM_SUFFIX}"
  local PROJECT_NAME="${BASE_PROJECT_NAME}-${ENV}"
  
  echo "-----------------------------------------------------"
  echo "Criando projeto: ${PROJECT_NAME} com ID: ${PROJECT_ID}"
  echo "-----------------------------------------------------"
  
  # 1. Cria o projeto
  echo "► Passo 1/3: Criando projeto..."
  if [[ -n "$ORGANIZATION_ID" ]]; then
    echo "  Criando projeto com organização ID: $ORGANIZATION_ID"
    if ! gcloud projects create ${PROJECT_ID} --name="${PROJECT_NAME}" --organization=${ORGANIZATION_ID}; then
      echo "✗ ERRO: Falha ao criar projeto $PROJECT_ID"
      return 1
    fi
  else
    echo "  Criando projeto sem organização (conta pessoal/sem org)"
    if ! gcloud projects create ${PROJECT_ID} --name="${PROJECT_NAME}"; then
      echo "✗ ERRO: Falha ao criar projeto $PROJECT_ID"
      return 1
    fi
  fi
  
  # Adicionar ao array de projetos criados para possível rollback
  CREATED_PROJECTS+=("$PROJECT_ID")
  echo "✓ Projeto $PROJECT_ID criado com sucesso"
  
  # 2. Vincula a conta de faturamento ao projeto
  echo "► Passo 2/3: Vinculando conta de faturamento..."
  if ! gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID}; then
    echo "✗ ERRO: Falha ao vincular billing account ao projeto $PROJECT_ID"
    return 1
  fi
  echo "✓ Billing account vinculada com sucesso"
  
  # 3. Ativa uma API no projeto (ex: Compute Engine)
  echo "► Passo 3/3: Ativando APIs necessárias..."
  if ! gcloud services enable compute.googleapis.com --project=${PROJECT_ID}; then
    echo "✗ ERRO: Falha ao ativar APIs no projeto $PROJECT_ID"
    return 1
  fi
  echo "✓ APIs ativadas com sucesso"
  
  echo "✓ Projeto ${PROJECT_ID} criado e configurado com sucesso!"
  echo ""
  
  # Retornar o PROJECT_ID
  echo "$PROJECT_ID"
}

##############################
# Função principal do script #
##############################

main() {
  # Não foram informados parâmetros ou foi pedido ajuda?
  if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
  fi

  # Opção para listar contas de billing
  if [[ "$1" == "--list-billing" ]]; then
    check_gcloud
    check_gcloud_auth
    echo "Contas de faturamento disponíveis:"
    gcloud beta billing accounts list --filter="open=true" --format="table(name,displayName,open)" 2>/dev/null || {
      echo "ERRO: Não foi possível listar as contas de billing."
      echo "Verifique suas permissões."
      exit 1
    }
    exit 0
  fi

  # Configurar trap para limpeza em caso de erro ou interrupção
  trap 'cleanup_on_error $?' ERR EXIT

  # O gcloud CLI está instalado?
  check_gcloud

  # O usuário está autenticado no gcloud?
  check_gcloud_auth

  local AUTO_BILLING=false
  local BILLING_ACCOUNT_ID=""
  local ORGANIZATION_ID=""
  local BASE_PROJECT_NAME=""

  # Verificar se é modo auto-billing
  if [[ "$1" == "--auto-billing" ]]; then
    AUTO_BILLING=true
    shift # Remove --auto-billing dos argumentos
  fi

  # Processar argumentos baseado no modo
  if [[ "$AUTO_BILLING" == true ]]; then
    # Modo auto-billing: --auto-billing [ORGANIZATION_ID] BASE_PROJECT_NAME
    if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
      echo "ERRO: Número incorreto de parâmetros para modo --auto-billing."
      echo "Uso: $0 --auto-billing [ORGANIZATION_ID] BASE_PROJECT_NAME"
      echo "Use '$0 --help' para ver instruções completas."
      exit 1
    fi

    # Detectar conta de billing automaticamente
    BILLING_ACCOUNT_ID=$(get_billing_account)
    if [[ $? -ne 0 ]] || [[ -z "$BILLING_ACCOUNT_ID" ]]; then
      echo "ERRO: Falha ao detectar conta de billing automaticamente."
      exit 1
    fi

    if [[ $# -eq 1 ]]; then
      # Apenas BASE_PROJECT_NAME
      BASE_PROJECT_NAME="$1"
    elif [[ $# -eq 2 ]]; then
      # ORGANIZATION_ID BASE_PROJECT_NAME
      ORGANIZATION_ID="$1"
      BASE_PROJECT_NAME="$2"
    fi
  else
    # Modo tradicional: BILLING_ACCOUNT_ID [ORGANIZATION_ID] BASE_PROJECT_NAME
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

    BILLING_ACCOUNT_ID="$1"

    if [[ $# -eq 2 ]]; then
      # 2 parâmetros: billing + project (sem organização)
      BASE_PROJECT_NAME="$2"
    elif [[ $# -eq 3 ]]; then
      # 3 parâmetros: billing + org + project
      ORGANIZATION_ID="$2"
      BASE_PROJECT_NAME="$3"
    fi
  fi

  # Se organization foi especificada como "none", tratar como vazio
  if [[ "$ORGANIZATION_ID" == "none" ]] || [[ "$ORGANIZATION_ID" == "None" ]] || [[ "$ORGANIZATION_ID" == "NONE" ]]; then
    ORGANIZATION_ID=""
  fi

  # Validar formato do BILLING_ACCOUNT_ID (apenas se não foi auto-detectado)
  if [[ "$AUTO_BILLING" == false ]] && [[ ! "$BILLING_ACCOUNT_ID" =~ ^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$ ]]; then
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

  # Lista de ambientes
  ENVIRONMENTS=("dev" "prod")

  # Mostrar resumo e solicitar confirmação
  confirm_project_creation "$BILLING_ACCOUNT_ID" "$ORGANIZATION_ID" "$BASE_PROJECT_NAME" "$AUTO_BILLING"

  # Habilitar modo de erro (para que o script pare em qualquer erro)
  set -e

  echo ""
  echo "🚀 Iniciando criação de projetos..."
  echo ""

  # ============================================
  # SEÇÃO: EXECUÇÃO
  # ============================================

  # --- EXECUÇÃO ATÔMICA ---
  for ENV in "${ENVIRONMENTS[@]}"
  do
    if ! create_project "$ENV" "$ORGANIZATION_ID" "$BILLING_ACCOUNT_ID" "$BASE_PROJECT_NAME"; then
      echo "✗ ERRO: Falha ao criar projeto para ambiente $ENV"
      exit 1
    fi
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
}

main "$@"