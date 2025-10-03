# Template de Engenharia de Dados - GCP

Template completo para projetos de Engenharia de Dados na Google Cloud Platform (GCP), utilizando Terraform para infraestrutura como código (IaC) e Cloud Run Jobs para processamento de dados.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Configuração Inicial](#-configuração-inicial)
- [Deploy](#-deploy)
- [Uso](#-uso)
- [Módulos Terraform](#-módulos-terraform)
- [Contribuindo](#-contribuindo)

## 🎯 Visão Geral

Este template fornece uma estrutura completa e padronizada para implementar pipelines de dados no GCP:

- **Infraestrutura como Código (IaC)** com Terraform
- **Arquitetura Lakehouse** (Bronze, Silver, Gold)
- **Cloud Run Jobs** para processamento de dados
- **Workflows** do GCP para orquestração
- **CI/CD** automatizado para múltiplos ambientes
- **BigQuery** para armazenamento e análise de dados
- **Cloud Storage** para data lake

## 🏗️ Arquitetura

### Camadas de Dados (Lakehouse)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Reception  │────▶│   Bronze    │────▶│   Silver    │────▶│    Gold     │
│   Layer     │     │   Layer     │     │   Layer     │     │   Layer     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
   Raw Data         Dados Brutos      Dados Limpos      Dados Agregados
```

- **Reception**: Dados brutos de ingestão inicial
- **Bronze**: Dados sem tratamento, histórico completo
- **Silver**: Dados limpos e validados
- **Gold**: Dados agregados e prontos para consumo

### Componentes Principais

- **Cloud Storage**: Armazenamento de dados em formato Parquet
- **BigQuery**: Data warehouse para análise
- **Cloud Run Jobs**: Processamento de dados containerizado
- **Workflows**: Orquestração de pipelines
- **Artifact Registry**: Registro de imagens Docker

## 🔧 Pré-requisitos

### Ferramentas Necessárias

- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install) - CLI do GCP
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Docker](https://docs.docker.com/get-docker/) - Para build de containers
- [Git](https://git-scm.com/downloads) - Controle de versão
- [Python](https://www.python.org/downloads/) >= 3.9 (para desenvolvimento de jobs)

### Permissões no GCP

O usuário ou service account precisa das seguintes permissões:

- `roles/owner` ou conjunto de roles específicas:
  - `roles/compute.admin`
  - `roles/storage.admin`
  - `roles/bigquery.admin`
  - `roles/run.admin`
  - `roles/workflows.admin`
  - `roles/artifactregistry.admin`
  - `roles/iam.serviceAccountAdmin`

## 📁 Estrutura do Projeto

```
.
├── 000_infrastructure/          # Infraestrutura Terraform
│   ├── 000_locals.tf           # Variáveis locais
│   ├── 000_variables.tf        # Variáveis de entrada
│   ├── 001_providers.tf        # Configuração de providers
│   ├── 002_apis.tf             # APIs do GCP
│   ├── 003_iam.tf              # Service accounts e permissões
│   ├── 004_artifactory.tf      # Artifact Registry
│   ├── 005_cloudrun.tf         # Cloud Run Jobs
│   ├── 006_bigquery.tf         # BigQuery (lakehouse)
│   ├── 007_workflows.tf        # Workflows de orquestração
│   ├── inventories/            # Configurações por ambiente
│   │   ├── backend/            # Backend do Terraform
│   │   │   ├── dev.conf
│   │   │   └── prd.conf
│   │   ├── env/                # Variáveis de ambiente
│   │   │   ├── dev.env
│   │   │   └── prd.env
│   │   └── tfvars/             # Variáveis Terraform
│   │       ├── dev.tfvars
│   │       └── prd.tfvars
│   └── modules/                # Módulos Terraform reutilizáveis
│       ├── cloud_run_job/      # Módulo de Cloud Run Jobs
│       ├── lakehouse/          # Módulo de Lakehouse (BigQuery + Storage)
│       └── workflow/           # Módulo de Workflows
│
├── 001_jobs/                   # Jobs de processamento de dados
│   ├── Dockerfile              # Imagem Docker para Cloud Run
│   ├── requirements.txt        # Dependências Python
│   ├── 000_sample/             # Job de exemplo
│   │   └── main.py
│   └── shared/                 # Módulos compartilhados
│       └── shared_module.py
│
├── 002_orquestration/          # Workflows de orquestração
│   └── 001_sample_workflow.yaml
│
├── 999_cicd/                   # Scripts de CI/CD
│   ├── 00_create_project.bash  # Criação de projeto GCP
│   └── 01_deploy.bash          # Deploy automatizado
│
├── README.md                   # Este arquivo
├── requirements.txt            # Dependências do projeto
└── TODO.md                     # Tarefas pendentes
```

## 🚀 Configuração Inicial

### 1. Criar Projeto no GCP

Execute o script para criar um novo projeto GCP e configurar o billing:

```bash
bash 999_cicd/00_create_project.bash
```

Este script irá:
- Criar ou utilizar um projeto GCP existente
- Vincular uma conta de faturamento
- Criar um bucket para o state do Terraform

Crie ao menos 2 projetos: uma para ambiente de DEV e outro para PROD.

### 2. Configurar Ambientes

Crie os arquivos de configuração para cada ambiente em `000_infrastructure/inventories/`:

#### Backend Configuration (`backend/<ambiente>.conf`)

```hcl
bucket = "bucket-terraform-tfstate-<project-id>"
prefix = "terraform.tfstate"
```

#### Environment Variables (`env/<ambiente>.env`)

```bash
TF_VAR_project_id=seu-project-id
TF_VAR_region=southamerica-east1
TF_VAR_artifact_registry_name=docker-repo
TF_VAR_artifact_image_name_to_cloud_run=cloud-run-image
```

#### Terraform Variables (`tfvars/<ambiente>.tfvars`)

```hcl
bronze_dataset_name   = "bronze_layer"
silver_dataset_name   = "silver_layer"
gold_dataset_name     = "gold_layer"
reception_bucket_name = "bucket-reception-layer-<project-id>"
bronze_bucket_name    = "bucket-bronze-layer-<project-id>"
silver_bucket_name    = "bucket-silver-layer-<project-id>"
gold_bucket_name      = "bucket-gold-layer-<project-id>"
```

### 3. Autenticação no GCP

```bash
# Login no GCP
gcloud auth login

# Configurar projeto
gcloud config set project <seu-project-id>

# Autenticar Docker para Artifact Registry
gcloud auth configure-docker <regiao>-docker.pkg.dev
```

## 🚢 Deploy

### Deploy Completo

Execute o script de deploy passando a branch e o ambiente:

```bash
bash 999_cicd/01_deploy.bash <branch-name> <ambiente>
```

Exemplo:
```bash
bash 999_cicd/01_deploy.bash dev dev
bash 999_cicd/01_deploy.bash main prd
```

O script irá:
1. Validar todas as dependências (git, terraform, gcloud, docker)
2. Baixar o código da branch especificada
3. Carregar as variáveis de ambiente
4. Fazer build e push da imagem Docker para o Artifact Registry
5. Executar `terraform init` e `terraform apply`

## 💻 Uso

### Criar um Novo Job

1. Crie um novo diretório em `001_jobs/`:

```bash
mkdir 001_jobs/002_meu_job
```

2. Crie o arquivo `main.py`:

```python
import os
from google.cloud import bigquery

def main():
    project_id = os.environ.get("PROJECT_ID")
    # Seu código aqui
    print(f"Executando job no projeto: {project_id}")

if __name__ == "__main__":
    main()
```

3. Adicione o job no Terraform (`000_infrastructure/005_cloudrun.tf`):

```hcl
module "meu_job" {
  source = "./modules/cloud_run_job"

  name                  = "meu-job"
  location              = var.region
  project_id            = var.project_id
  service_account_email = google_service_account.cloud_run_job_service_account.email
  artifact_image_path   = local.artifact_image_path
  args                  = ["python", "002_meu_job/main.py"]
  cpu_limit             = "2"
  memory_limit          = "1Gi"
  max_retries           = 1
  
  env_vars = {
    PROJECT_ID = var.project_id
  }
}
```

4. Execute o deploy:

```bash
bash 999_cicd/01_deploy.bash dev dev
```

### Criar um Novo Workflow

1. Crie o arquivo YAML em `002_orquestration/`:

```yaml
main:
  params: [args]
  steps:
  - init:
      assign:
      - project_id: ${project_id}
      - region: ${region}

  - run_job:
      call: googleapis.run.v1.namespaces.jobs.run
      args:
        name: $${"namespaces/" + project_id + "/jobs/" + "meu-job"}
        location: ${region}

  - finish:
      return: "Workflow completed"
```

2. Adicione o workflow no Terraform (`000_infrastructure/007_workflows.tf`):

```hcl
module "meu_workflow" {
  source = "./modules/workflow"

  name                  = "meu-workflow"
  location              = var.region
  project_id            = var.project_id
  service_account_email = google_service_account.cloud_run_job_service_account.email
  workflow_yaml_path    = "${path.module}/../002_orquestration/002_meu_workflow.yaml"

  template_vars = {
    project_id = var.project_id
    region     = var.region
  }

  description = "Meu workflow customizado"
  
  labels = {
    environment = "dev"
  }
}
```

## 🧩 Módulos Terraform

### Cloud Run Job

Cria um Cloud Run Job para processamento de dados.

**Variáveis principais:**
- `name`: Nome do job
- `artifact_image_path`: Caminho da imagem no Artifact Registry
- `args`: Argumentos de execução
- `cpu_limit`: Limite de CPU (ex: "1", "2")
- `memory_limit`: Limite de memória (ex: "512Mi", "1Gi")
- `env_vars`: Variáveis de ambiente

### Lakehouse

Cria a arquitetura de lakehouse com BigQuery e Cloud Storage.

**Componentes:**
- 4 buckets GCS (Reception, Bronze, Silver, Gold)
- 3 datasets BigQuery (Bronze, Silver, Gold)
- Tabelas de exemplo (managed e external)

### Workflow

Cria um Workflow do GCP para orquestração de jobs.

**Variáveis principais:**
- `workflow_yaml_path`: Caminho do arquivo YAML
- `template_vars`: Variáveis a serem substituídas no template
- `service_account_email`: Service account para execução

## 🛠️ Desenvolvimento

### Instalar Dependências Locais

```bash
pip install -r requirements.txt
```

### Estrutura de Dependências

- **BigQuery**: `google-cloud-bigquery`
- **Storage**: `google-cloud-storage`
- **Logging**: `google-cloud-logging`
- **Data Processing**: `pandas`, `numpy`, `pyarrow`
- **HTTP Requests**: `requests`

### Boas Práticas

1. **Módulos Compartilhados**: Coloque código reutilizável em `001_jobs/shared/`
2. **Variáveis de Ambiente**: Use variáveis de ambiente para configurações
3. **Logging**: Use Cloud Logging para monitoramento
4. **Idempotência**: Garanta que seus jobs possam ser executados múltiplas vezes
5. **Particionamento**: Use partições no BigQuery para otimizar custos

## 🤝 Contribuindo

1. Crie uma branch para sua feature: `git checkout -b feature/minha-feature`
2. Faça commit das suas mudanças: `git commit -m 'feat: adiciona nova feature'`
3. Push para a branch: `git push origin feature/minha-feature`
4. Abra um Pull Request

### Convenção de Commits

Seguimos o padrão [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Mudanças na documentação
- `refactor`: Refatoração de código
- `test`: Adição ou modificação de testes
- `chore`: Tarefas de manutenção

## 📝 Licença

Este é um template privado para uso em projetos de consultoria de engenharia de dados.