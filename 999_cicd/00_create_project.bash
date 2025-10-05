#!/bin/bash

# Script para criar um projeto no Google Cloud, vincular uma conta de faturamento e criar um bucket GCS.
# Autor: Guilherme dos Santos Magalhães
# Data: 2025-09-27

# Versão 1.0
#	- Criação inicial do script

# ------------- Constantes e configurações iniciais ------------- #
# Encerra o script se qualquer comando falhar
set -e

# Nome base para o bucket (será complementado com o ID do projeto)
BASE_BUCKET_NAME="bucket-terraform-tfstate"

# ------------- Função para selecionar e vincular conta de faturamento ------------- #
# Recebe o ID do projeto como argumento ($1)
link_billing_account() {
	local project_id_to_link=$1
	echo ">>> Listando contas de faturamento disponíveis..."
	mapfile -t billing_accounts < <(gcloud beta billing accounts list --format="value(ACCOUNT_ID, DISPLAY_NAME)" --filter="OPEN=true")

	if [ ${#billing_accounts[@]} -eq 0 ]; then
		echo "Erro: Nenhuma conta de faturamento ativa foi encontrada."
		exit 1
	fi

	echo "Selecione uma conta de faturamento para vincular ao projeto '$project_id_to_link':"
	for i in "${!billing_accounts[@]}"; do
		printf "  %d) %s\n" "$((i + 1))" "${billing_accounts[$i]}"
	done

	read -p "Digite o número da conta desejada: " choice
	if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#billing_accounts[@]} ]; then
		echo "Erro: Seleção inválida."
		exit 1
	fi

	local billing_account_id
	billing_account_id=$(echo "${billing_accounts[$((choice - 1))]}" | awk '{print $1}')

	echo ">>> Vinculando a conta de faturamento '$billing_account_id' ao projeto '$project_id_to_link'..."
	if ! gcloud beta billing projects link "$project_id_to_link" --billing-account="$billing_account_id"; then
		echo "Erro: Falha ao vincular a conta de faturamento."
		exit 1
	fi
	echo "Conta de faturamento vinculada com sucesso."
}

# ------------- Verificações iniciais ------------- #
echo ">>> Verificando gcloud e autenticação..."
if ! command -v gcloud &>/dev/null; then
	echo "Erro: O 'gcloud' não foi encontrado. Por favor, instale o Google Cloud SDK."
	exit 1
fi

if ! gcloud config get-value account &>/dev/null; then
	echo "Erro: Nenhum usuário autenticado. Por favor, execute 'gcloud auth login'."
	exit 1
fi

CURRENT_USER=$(gcloud config get-value account)
echo "gcloud encontrado e usuário '$CURRENT_USER' autenticado."

# ------------- Obter Nome do Projeto ------------- #
echo ">>> Definição do nome do projeto..."
read -p "Digite o NOME do projeto (ex: Meu Projeto de Dados): " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
	echo "Erro: O nome do projeto não pode ser vazio."
	exit 1
fi

# ------------- Verificar se o projeto já existe pelo nome ------------- #
echo ">>> Verificando se um projeto com o nome '$PROJECT_NAME' já existe..."
EXISTING_PROJECT_ID=$(gcloud projects list --filter="name='$PROJECT_NAME'" --format="value(projectId)" | head -n 1)

if [ -n "$EXISTING_PROJECT_ID" ]; then
	# O projeto já existe
	PROJECT_ID="$EXISTING_PROJECT_ID"
	echo "Projeto com nome '$PROJECT_NAME' já existe com o ID: '$PROJECT_ID'."

	# Verifica se o projeto existente possui uma conta de faturamento ativa
	echo ">>> Verificando status do faturamento para o projeto existente..."
	if ! gcloud beta billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" | grep -q "True"; then
		echo "O projeto existente '$PROJECT_ID' não possui uma conta de faturamento ativa."
		link_billing_account "$PROJECT_ID"
	else
		echo "A conta de faturamento já está ativa para este projeto."
	fi
else
	# O projeto não existe
	echo "Nenhum projeto encontrado com o nome '$PROJECT_NAME'. Prosseguindo para a criação."

	# ------------- Gerar ID (Apenas para projetos novos) ------------- #
	echo ">>> Gerando ID de projeto..."
	CLEAN_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/--\+/-/g' -e 's/^-//' -e 's/-$//' | cut -c 1-20)
	RANDOM_SUFFIX=$(shuf -i 100000-999999 -n 1)
	PROJECT_ID="${CLEAN_NAME}-${RANDOM_SUFFIX}"

	# ------------- Resumo e Confirmação (Apenas para projetos novos) ------------- #
	echo ">>> Resumo da operação"
	echo "--------------------------------------------------"
	echo "Nome do Projeto:           $PROJECT_NAME"
	echo "ID do Projeto (a ser gerado):    $PROJECT_ID"
	echo "--------------------------------------------------"
	read -p "Confirmar a criação deste novo projeto? (s/n): " confirm
	if [[ "${confirm,,}" != "s" ]]; then
		echo "Operação cancelada pelo usuário."
		exit 0
	fi

	# ------------- Criação do Projeto e Vinculação de Faturamento (Apenas para projetos novos) ------------- #
	echo ">>> Criando o projeto '$PROJECT_ID'..."
	if ! gcloud projects create "$PROJECT_ID" --name="$PROJECT_NAME"; then
		echo "Erro: Falha ao criar o projeto. Verifique suas permissões ou a cota de projetos."
		exit 1
	fi
	echo "Projeto '$PROJECT_ID' criado com sucesso."
	link_billing_account "$PROJECT_ID"
fi

# ------------- Criação do Bucket (Executa para projetos novos e existentes) ------------- #
BUCKET_NAME="${BASE_BUCKET_NAME}-${PROJECT_ID}"
echo ">>> Verificando e criando o bucket GCS 'gs://$BUCKET_NAME'..."
gcloud services enable storage.googleapis.com --project="$PROJECT_ID"

if gcloud storage buckets describe "gs://$BUCKET_NAME" &>/dev/null; then
	echo "Bucket 'gs://$BUCKET_NAME' já existe. Nenhuma ação necessária."
else
	echo ">>> Criando o bucket 'gs://$BUCKET_NAME'..."
	if gcloud storage buckets create "gs://$BUCKET_NAME" --project="$PROJECT_ID" --location="US" --uniform-bucket-level-access; then
		echo "Bucket 'gs://$BUCKET_NAME' criado com sucesso!"
	else
		echo "Erro: Falha ao criar o bucket 'gs://$BUCKET_NAME'. Verifique as permissões."
		exit 1
	fi
fi

# ------------- Resumo Final ------------- #
echo ""
echo ">>> Resumo Final"
echo "--------------------------------------------------"
echo "Nome do Projeto:    $PROJECT_NAME"
echo "ID do Projeto:      $PROJECT_ID"
echo "Nome do Bucket:     $BUCKET_NAME"
echo "Path do Bucket:     gs://$BUCKET_NAME"
echo "--------------------------------------------------"
echo ""
echo "Script concluído com sucesso!"
