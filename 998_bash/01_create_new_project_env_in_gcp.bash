#!/bin/bash

#####################
# Variáveis globais #
#####################

# Lista de ambientes que serão criados (um projeto para cada)
ENVIRONMENTS=("dev" "prod")

# Arrays para armazenar projetos e buckets criados (para possível rollback)
CREATED_PROJECTS=()
CREATED_BUCKETS=()

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

##########################
# Verificações do gcloud #
##########################

# Verfica se o gcloud CLI está instalado
# Retorna 1 se não estiver instalado, 0 se estiver instalado
check_gcloud() {
  if ! command -v gcloud &> /dev/null; then
    echo "ERRO: O programa 'gcloud' não está instalado."
    echo "Por favor, instale o Google Cloud CLI antes de executar este script."
    echo "Instruções: https://cloud.google.com/sdk/docs/install"
    return 1
  fi
  
  echo "✓ Google Cloud CLI encontrado: $(gcloud --version | head -n1)"
  return 0
}

# Verifica se há um usuário autenticado no gcloud
# Retorna 1 se não estiver autenticado ou se as credenciais forem inválidas, 0 se estiver autenticado
check_gcloud_auth() {
  echo "Verificando autenticação no Google Cloud..."
  
  # Verifica se há uma conta ativa
  ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
  
  if [[ -z "$ACTIVE_ACCOUNT" ]] || [[ "$ACTIVE_ACCOUNT" == "(unset)" ]]; then
    echo "ERRO: Nenhuma conta está autenticada no gcloud."
    echo "Por favor, execute 'gcloud auth login' para fazer login."
    return 1
  fi
  
  # Testa se as credenciais são válidas fazendo uma chamada simples
  if ! gcloud projects list --limit=1 &>/dev/null; then
    echo "ERRO: Credenciais do gcloud expiradas ou inválidas."
    echo "Por favor, execute 'gcloud auth login' para renovar as credenciais."
    return 1
  fi
  
  echo "✓ Autenticado como: $ACTIVE_ACCOUNT"
  return 0
}

###################
# Funcionalidades #
###################

# Função que lista todas as contas de billing ativas disponíveis
# Retorna um array com os IDs das contas (formato: XXXXXX-XXXXXX-XXXXXX)
# Retorna 1 se não houver contas ou se ocorrer um erro
list_billing_accounts() {
  # Lista todas as contas de billing ativas
  local BILLING_ACCOUNTS
  BILLING_ACCOUNTS=$(gcloud beta billing accounts list --filter="open=true" --format="value(name)" 2>/dev/null)
  
  if [[ -z "$BILLING_ACCOUNTS" ]]; then
    echo "ERRO: Nenhuma conta de faturamento ativa encontrada." >&2
    echo "Verifique se você tem permissões para acessar contas de faturamento." >&2
    return 1
  fi
  
  # Converte a lista em um array e extrai apenas os IDs
  local ACCOUNTS_ARRAY=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      # Extrai apenas o ID da conta (formato: billingAccounts/XXXXXX-XXXXXX-XXXXXX)
      local ACCOUNT_ID=$(echo "$line" | sed 's|billingAccounts/||')
      ACCOUNTS_ARRAY+=("$ACCOUNT_ID")
    fi
  done <<< "$BILLING_ACCOUNTS"
  
  # Retorna o array via stdout
  printf '%s\n' "${ACCOUNTS_ARRAY[@]}"
  return 0
}

# Função para mostrar contas de billing disponíveis
show_billing_accounts() {
  echo "Recuperando contas de faturamento disponíveis..."
  local BILLING_ACCOUNTS
  BILLING_ACCOUNTS=$(gcloud beta billing accounts list --filter="open=true" --format="table(name,displayName,open)" 2>/dev/null)

  echo "Contas de faturamento disponíveis:"
  echo "$BILLING_ACCOUNTS"
  
}

# Função que identifica automaticamente uma conta de billing
# Se houver apenas uma conta, retorna ela automaticamente
# Se houver múltiplas, retorna erro e informa ao usuário
get_auto_billing_account() {
  echo "Detectando contas de faturamento disponíveis..." >&2
  
  # Obter lista de contas usando a função list_billing_accounts
  local ACCOUNTS_ARRAY=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      ACCOUNTS_ARRAY+=("$line")
    fi
  done < <(list_billing_accounts)
  
  # Se houve erro na listagem, propagar o erro
  if [[ $? -ne 0 ]] || [[ ${#ACCOUNTS_ARRAY[@]} -eq 0 ]]; then
    return 1
  fi
  
  # Se há apenas uma conta, usa ela automaticamente
  if [[ ${#ACCOUNTS_ARRAY[@]} -eq 1 ]]; then
    echo "✓ Conta de faturamento detectada automaticamente: ${ACCOUNTS_ARRAY[0]}" >&2
    echo "${ACCOUNTS_ARRAY[0]}"
    return 0
  fi
  
  # Se há múltiplas contas, retorna erro e informa o usuário
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

# Função para mostrar resumo e pedir confirmação
# Parâmetros:
#   $1 = BILLING_ACCOUNT_ID
#   $2 = ORGANIZATION_ID
#   $3 = BASE_PROJECT_NAME
#   $4 = AUTO_BILLING (true/false)
confirm_project_creation() {
  local BILLING_ACCOUNT_ID="$1"
  local ORGANIZATION_ID="$2"
  local BASE_PROJECT_NAME="$3"
  local AUTO_BILLING="$4"
  
  echo ""
  echo "===================================================================="
  echo "=                    RESUMO DA OPERAÇÃO                            ="
  echo "===================================================================="
  echo ""
  echo "📋 O que será criado:"
  echo "   • 2 projetos no Google Cloud Platform"
  echo "   • Buckets do Cloud Storage para Terraform state"
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
  echo "   • APIs do Compute Engine e Cloud Storage serão ativadas"
  echo "   • Buckets para Terraform state serão criados com versionamento"
  echo "   • Projetos serão configurados e prontos para uso"
  echo ""
  echo "===================================================================="
  echo "=                           ATENÇÃO                                ="
  echo "===================================================================="
  echo ""
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
        return 1
        ;;
      *)
        echo "❓ Resposta inválida. Digite 's' para SIM ou 'n' para NÃO."
        ;;
    esac
  done
}

# Função para criar um projeto no GCP
# Parâmetros:
#   $1 = ENV (dev ou prod)
#   $2 = ORGANIZATION_ID (pode ser vazio)
#   $3 = BILLING_ACCOUNT_ID
#   $4 = BASE_PROJECT_NAME
create_project() {
  local ENV=$1
  local ORGANIZATION_ID=$2
  local BILLING_ACCOUNT_ID=$3
  local BASE_PROJECT_NAME=$4
  
  # Gera um sufixo aleatório para garantir um ID único
  local RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)
  local PROJECT_ID="${BASE_PROJECT_NAME}-${ENV}-${RANDOM_SUFFIX}"
  local PROJECT_NAME="${BASE_PROJECT_NAME}-${ENV}"
  
  echo "===================================================================="
  echo "=     Criando projeto: ${PROJECT_NAME} com ID: ${PROJECT_ID}       ="
  echo "===================================================================="

  # 1. Cria o projeto
  echo "► Passo 1/3: Criando projeto..." >&2
  if [[ -n "$ORGANIZATION_ID" ]]; then
    echo "  Criando projeto com organização ID: $ORGANIZATION_ID" >&2
    if ! gcloud projects create ${PROJECT_ID} --name="${PROJECT_NAME}" --organization=${ORGANIZATION_ID} >&2; then
      echo "✗ ERRO: Falha ao criar projeto $PROJECT_ID" >&2
      return 1
    fi
  else
    echo "  Criando projeto sem organização (conta pessoal/sem org)" >&2
    if ! gcloud projects create ${PROJECT_ID} --name="${PROJECT_NAME}" >&2; then
      echo "✗ ERRO: Falha ao criar projeto $PROJECT_ID" >&2
      return 1
    fi
  fi
  
  # Adicionar ao array de projetos criados para possível rollback
  CREATED_PROJECTS+=("$PROJECT_ID")
  echo "✓ Projeto $PROJECT_ID criado com sucesso" >&2
  
  # 2. Vincula a conta de faturamento ao projeto
  echo "► Passo 2/3: Vinculando conta de faturamento..." >&2
  if ! gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID} >&2; then
    echo "✗ ERRO: Falha ao vincular billing account ao projeto $PROJECT_ID" >&2
    return 1
  fi
  echo "✓ Billing account vinculada com sucesso" >&2
  
  # 3. Ativa APIs necessárias no projeto
  echo "► Passo 3/3: Ativando APIs necessárias..." >&2
  if ! gcloud services enable compute.googleapis.com storage.googleapis.com --project=${PROJECT_ID} >&2; then
    echo "✗ ERRO: Falha ao ativar APIs no projeto $PROJECT_ID" >&2
    return 1
  fi
  echo "✓ APIs ativadas com sucesso (Compute Engine e Cloud Storage)" >&2
  
  echo "✓ Projeto ${PROJECT_ID} criado e configurado com sucesso!" >&2
  echo "" >&2
  
  # Retornar apenas o PROJECT_ID (stdout limpo)
  echo "$PROJECT_ID"
}

# Função para gerar nome do bucket do Terraform
# Parâmetros:
#   $1 = PROJECT_ID
generate_terraform_bucket_name() {
  local PROJECT_ID=$1
  echo "${PROJECT_ID}-terraform-state"
}

# Função para criar um bucket do Cloud Storage para o Terraform state
# Parâmetros:
#   $1 = PROJECT_ID
#   $2 = ENV (dev ou prod)
create_bucket() {
  local BUCKET_NAME=$1
  
  echo "===================================================================="
  echo "=              Criando bucket: ${BUCKET_NAME}                      ="
  echo "===================================================================="

  
  echo "► Criando bucket: ${BUCKET_NAME}" >&2
  
  # Criar o bucket com configurações adequadas para Terraform state
  if ! gcloud storage buckets create gs://${BUCKET_NAME} \
    --project=${PROJECT_ID} \
    --location=US \
    --uniform-bucket-level-access \
    --public-access-prevention >&2; then
    echo "✗ ERRO: Falha ao criar bucket ${BUCKET_NAME}" >&2
    return 1
  fi
  
  echo "► Configurando versionamento no bucket..." >&2
  if ! gcloud storage buckets update gs://${BUCKET_NAME} --versioning --project=${PROJECT_ID} >&2; then
    echo "✗ ERRO: Falha ao configurar versionamento no bucket ${BUCKET_NAME}" >&2
    return 1
  fi
  
  echo "✓ Bucket ${BUCKET_NAME} criado e configurado com sucesso!" >&2
  echo "  - Versionamento habilitado" >&2
  echo "  - Acesso público bloqueado" >&2
  echo "  - Uniform bucket-level access habilitado" >&2
  echo "" >&2
  
  # Adicionar ao array de buckets criados para possível rollback
  CREATED_BUCKETS+=("${BUCKET_NAME}")
  
  return 0
}

# Função para desfazer (rollback) projetos e buckets criados em caso de erro
# Utiliza as variaveis globais CREATED_PROJECTS e CREATED_BUCKETS
rollback() {  
  echo "===================================================================="
  echo "=                   INICIANDO ROLLBACK                             ="
  echo "===================================================================="

  if [[ ${#CREATED_PROJECTS[@]} -eq 0 ]] && [[ ${#CREATED_BUCKETS[@]} -eq 0 ]]; then
    echo "Nenhum projeto ou bucket foi criado. Nada para desfazer."
    return
  fi

  # Primeiro tentar remover buckets (antes dos projetos)
  if [[ ${#CREATED_BUCKETS[@]} -gt 0 ]]; then
    echo "Removendo buckets criados..."
    for BUCKET_NAME in "${CREATED_BUCKETS[@]}"; do
      echo "Removendo bucket: $BUCKET_NAME"
      
      # Tentar deletar o bucket (forçar remoção mesmo com objetos)
      if gcloud storage rm -r gs://"$BUCKET_NAME" 2>/dev/null; then
        echo "✓ Bucket $BUCKET_NAME removido com sucesso"
      else
        echo "✗ Falha ao remover bucket $BUCKET_NAME (pode precisar ser removido manualmente)"
      fi
    done
  fi
  
  # Depois remover projetos
  if [[ ${#CREATED_PROJECTS[@]} -gt 0 ]]; then
    echo "Removendo projetos criados..."
    for PROJECT_ID in "${CREATED_PROJECTS[@]}"; do
      echo "Removendo projeto: $PROJECT_ID"
      
      # Tentar deletar o projeto
      if gcloud projects delete "$PROJECT_ID" --quiet 2>/dev/null; then
        echo "✓ Projeto $PROJECT_ID removido com sucesso"
      else
        echo "✗ Falha ao remover projeto $PROJECT_ID (pode precisar ser removido manualmente)"
      fi
    done
  fi

  echo "===================================================================="
  echo "=                   ROLLBACK CONCLUÍDO                             ="
  echo "===================================================================="

  return 1
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

  # O gcloud CLI está instalado?
  if ! check_gcloud; then
    exit 1
  fi

  # O usuário está autenticado no gcloud?
  if ! check_gcloud_auth; then
    exit 1
  fi

  # Opção para listar contas de billing
  if [[ "$1" == "--list-billing" ]]; then
    show_billing_accounts || {
      echo "ERRO: Falha ao listar contas de faturamento." >&2
      exit 1
    }
    exit 0
  fi

  local AUTO_BILLING=false
  local BILLING_ACCOUNT_ID=""
  local ORGANIZATION_ID=""
  local BASE_PROJECT_NAME=""

  # É modo automático de billing?
  if [[ "$1" == "--auto-billing" ]]; then
    AUTO_BILLING=true
    shift # Remove --auto-billing dos argumentos
  fi

  # Flag "auto-billing" foi informada?
  if [[ "$AUTO_BILLING" == true ]]; then
    if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
      echo "ERRO: Número incorreto de parâmetros para modo --auto-billing."
      echo "Uso: $0 --auto-billing [ORGANIZATION_ID] BASE_PROJECT_NAME"
      echo "Use '$0 --help' para ver instruções completas."
      exit 1
    fi

    # Detectar conta de billing automaticamente
    BILLING_ACCOUNT_ID=$(get_auto_billing_account)
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

  # Flag "auto-billing" não foi informada
  else
    # Não foram informados 2 ou 3 parâmetros?
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

  # O parâmetro "ORGANIZATION_ID" foi informado como "none"?
  if [[ "$ORGANIZATION_ID" == "none" ]] || [[ "$ORGANIZATION_ID" == "None" ]] || [[ "$ORGANIZATION_ID" == "NONE" ]]; then
    ORGANIZATION_ID=""
  fi

  # BILLING_ACCOUNT_ID possui formato válido?
  if [[ "$AUTO_BILLING" == false ]] && [[ ! "$BILLING_ACCOUNT_ID" =~ ^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$ ]]; then
    echo "AVISO: O formato do BILLING_ACCOUNT_ID pode estar incorreto."
    echo "Formato esperado: XXXXXX-XXXXXX-XXXXXX (onde X são números ou letras maiúsculas)"
    echo "Valor fornecido: $BILLING_ACCOUNT_ID"
    echo ""
  fi

  # ORGANIZATION_ID possui formato válido?
  if [[ -n "$ORGANIZATION_ID" ]] && [[ ! "$ORGANIZATION_ID" =~ ^[0-9]+$ ]]; then
    echo "ERRO: ORGANIZATION_ID deve conter apenas números."
    echo "Valor fornecido: $ORGANIZATION_ID"
    exit 1
  fi

  # Mostrar resumo e solicitar confirmação
  if ! confirm_project_creation "$BILLING_ACCOUNT_ID" "$ORGANIZATION_ID" "$BASE_PROJECT_NAME" "$AUTO_BILLING"; then
    echo "Operação cancelada."
    exit 0
  fi

  # Configurar trap para limpeza em caso de erro ou interrupção 
  trap 'rollback; exit 1' EXIT

  # Habilitar modo de erro (para que o script pare em qualquer erro)
  set -e

  echo ""
  echo "🚀 Iniciando criação de projetos..."
  echo ""

  for ENV in "${ENVIRONMENTS[@]}"
  do
    # Criar o projeto e capturar o PROJECT_ID
    PROJECT_ID=$(create_project "$ENV" "$ORGANIZATION_ID" "$BILLING_ACCOUNT_ID" "$BASE_PROJECT_NAME")
    if [[ $? -ne 0 ]] || [[ -z "$PROJECT_ID" ]]; then
      echo "✗ ERRO: Falha ao criar projeto para ambiente $ENV"
      exit 1
    fi

    BUCKET_NAME=$(generate_terraform_bucket_name "$PROJECT_ID")

    # Criar o bucket do Terraform para este projeto
    if ! create_bucket "$BUCKET_NAME"; then
      echo "✗ ERRO: Falha ao criar bucket Terraform para projeto $PROJECT_ID"
      exit 1
    fi
  done

  # Se chegou até aqui, todos os projetos foram criados com sucesso
  # Desabilitar trap de limpeza para não fazer rollback
  trap - ERR EXIT

  echo "=============================================="
  echo "= ✓ TODOS OS PROJETOS CRIADOS COM SUCESSO!   ="
  echo "=============================================="
  echo "Projetos criados:"
  for PROJECT_ID in "${CREATED_PROJECTS[@]}"; do
    echo "  - $PROJECT_ID"
  done
  echo ""
  echo "Buckets Terraform criados:"
  for BUCKET_NAME in "${CREATED_BUCKETS[@]}"; do
    echo "  - gs://$BUCKET_NAME"
  done
  echo "=============================================="
}

main "$@"