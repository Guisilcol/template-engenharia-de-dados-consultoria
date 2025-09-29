#!/bin/bash
# Script para criar um projeto no Google Cloud, vincular uma conta de faturamento e criar um bucket GCS.
# Autor: Guilherme dos Santos Magalhães 
# Data: 2024-06-27

# Versão 1.0 
#	- Criação inicial do script

set -o errexit
set -o nounset
set -o pipefail

# --- VARIÁVEIS GLOBAIS ---

# Nome base para o bucket (será complementado com o ID do projeto)
BASE_BUCKET_NAME="bucket-terraform-tfstate"

# --- FUNÇÕES DE UTILIDADES/LOG ---
fail() {
	echo -e "\n\e[31mErro: $1\e[0m" >&2
	exit 1
}
success() {
	echo -e "\e[32m$1\e[0m"
}
info() {
	echo -e "\e[33m$1\e[0m"
}

# --- FUNÇÃO PARA SELECIONAR E VINCULAR CONTA DE FATURAMENTO ---
# Recebe o ID do projeto como argumento ($1)
link_billing_account() {
	local project_id_to_link=$1
	info "Listando contas de faturamento disponíveis..."
	mapfile -t billing_accounts < <(gcloud beta billing accounts list --format="value(ACCOUNT_ID, DISPLAY_NAME)" --filter="OPEN=true")

	if [ ${#billing_accounts[@]} -eq 0 ]; then
		fail "Nenhuma conta de faturamento ativa foi encontrada."
	fi

	echo "Selecione uma conta de faturamento para vincular ao projeto '$project_id_to_link':"
	for i in "${!billing_accounts[@]}"; do
		printf "  %d) %s\n" "$((i + 1))" "${billing_accounts[$i]}"
	done

	read -p "Digite o número da conta desejada: " choice
	if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#billing_accounts[@]} ]; then
		fail "Seleção inválida."
	fi

	local billing_account_id
	billing_account_id=$(echo "${billing_accounts[$((choice - 1))]}" | awk '{print $1}')

	info "Vinculando a conta de faturamento '$billing_account_id' ao projeto '$project_id_to_link'..."
	if ! gcloud beta billing projects link "$project_id_to_link" --billing-account="$billing_account_id"; then
		fail "Falha ao vincular a conta de faturamento."
	fi
	success "Conta de faturamento vinculada com sucesso."
}

# --- 1. Verificações Iniciais ---
info "1/7: Verificando gcloud e autenticação..."
if ! command -v gcloud &>/dev/null; then
	fail "O 'gcloud' não foi encontrado. Por favor, instale o Google Cloud SDK."
fi
if ! gcloud config get-value account &>/dev/null; then
	fail "Nenhum usuário autenticado. Por favor, execute 'gcloud auth login'."
fi
CURRENT_USER=$(gcloud config get-value account)
success "gcloud encontrado e usuário '$CURRENT_USER' autenticado."

# --- 2. Obter Nome do Projeto ---
info "2/7: Definição do nome do projeto..."
read -p "Digite o NOME do projeto (ex: Meu Projeto de Dados): " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
	fail "O nome do projeto não pode ser vazio."
fi

# --- 3. VERIFICAR SE O PROJETO JÁ EXISTE PELO NOME ---
info "3/7: Verificando se um projeto com o nome '$PROJECT_NAME' já existe..."
EXISTING_PROJECT_ID=$(gcloud projects list --filter="name='$PROJECT_NAME'" --format="value(projectId)" | head -n 1)

if [ -n "$EXISTING_PROJECT_ID" ]; then
	# O PROJETO JÁ EXISTE
	PROJECT_ID="$EXISTING_PROJECT_ID"
	success "Projeto com nome '$PROJECT_NAME' já existe com o ID: '$PROJECT_ID'."

	# VERIFICA SE O PROJETO EXISTENTE POSSUI UMA CONTA DE FATURAMENTO ATIVA
	info "Verificando status do faturamento para o projeto existente..."
	if ! gcloud beta billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" | grep -q "True"; then
		info "O projeto existente '$PROJECT_ID' não possui uma conta de faturamento ativa."
		link_billing_account "$PROJECT_ID"
	else
		success "A conta de faturamento já está ativa para este projeto."
	fi
else
	# O PROJETO NÃO EXISTE
	info "Nenhum projeto encontrado com o nome '$PROJECT_NAME'. Prosseguindo para a criação."

	# --- 4. Gerar ID (Apenas para projetos novos) ---
	info "4/7: Gerando ID de projeto..."
	CLEAN_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/--\+/-/g' -e 's/^-//' -e 's/-$//' | cut -c 1-20)
	RANDOM_SUFFIX=$(shuf -i 100000-999999 -n 1)
	PROJECT_ID="${CLEAN_NAME}-${RANDOM_SUFFIX}"

	# --- 5. Resumo e Confirmação (Apenas para projetos novos) ---
	info "5/7: Resumo da operação"
	echo "--------------------------------------------------"
	echo "Nome do Projeto:           $PROJECT_NAME"
	echo "ID do Projeto (a ser gerado):    $PROJECT_ID"
	echo "--------------------------------------------------"
	read -p "Confirmar a criação deste novo projeto? (s/n): " confirm
	if [[ "${confirm,,}" != "s" ]]; then
		echo "Operação cancelada pelo usuário."
		exit 0
	fi

	# --- 6. Criação do Projeto e Vinculação de Faturamento (Apenas para projetos novos) ---
	info "6/7: Criando o projeto '$PROJECT_ID'..."
	if ! gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME"; then
		fail "Falha ao criar o projeto. Verifique suas permissões ou a cota de projetos."
	fi
	success "Projeto '$PROJECT_ID' criado com sucesso."
	link_billing_account "$PROJECT_ID"
fi

# --- 7. Criação do Bucket (Executa para projetos novos e existentes) ---
BUCKET_NAME="${BASE_BUCKET_NAME}-${PROJECT_ID}"
info "7/7: Verificando e criando o bucket GCS 'gs://$BUCKET_NAME'..."
gcloud services enable storage.googleapis.com --project="$PROJECT_ID"

if gcloud storage buckets describe "gs://$BUCKET_NAME" &>/dev/null; then
	success "Bucket 'gs://$BUCKET_NAME' já existe. Nenhuma ação necessária."
else
	info "Criando o bucket 'gs://$BUCKET_NAME'..."
	if gcloud storage buckets create "gs://$BUCKET_NAME" --project="$PROJECT_ID" --location="US" --uniform-bucket-level-access; then
		success "Bucket 'gs://$BUCKET_NAME' criado com sucesso!"
	else
		fail "Falha ao criar o bucket 'gs://$BUCKET_NAME'. Verifique as permissões."
	fi
fi

# --- RESUMO FINAL ---
info "\n--- Resumo Final ---"
echo "--------------------------------------------------"
echo "Nome do Projeto:    $PROJECT_NAME"
echo "ID do Projeto:      $PROJECT_ID"
echo "Nome do Bucket:     $BUCKET_NAME"
echo "Path do Bucket:     gs://$BUCKET_NAME"
echo "--------------------------------------------------"

echo -e "\n\e[1;32mScript concluído com sucesso!\e[0m"
