# Template de Engenharia de Dados — Consultoria GCP

Este projeto é um *template* completo de engenharia de dados sobre o Google Cloud Platform. Ele reúne:

- Infraestrutura como código (Terraform) que monta as camadas de ingestão, datasets, jobs, workflows, secrets e triggers.
- Jobs empacotados em Docker e executados pelo Cloud Run Jobs.
- Workflows e Cloud Scheduler capazes de orquestrar toda a cadeia.
- Exemplos de conexão entre buckets, tabelas e parâmetros de runtime.

A documentação abaixo mostra como entender cada bloco, como estender o projeto (novas tabelas, scripts, workflows) e como implantar em um ambiente Linux com `bash`.

## Arquitetura geral

1. **Infraestrutura (`000_infrastructure/`)**
   - Unicode: declara providers, APIs necessárias (`run`, `artifactregistry`, `logging`, `monitoring`, `secretmanager`, etc.).
   - Cria service account (com IAM bundling para BigQuery, Storage, Cloud Run e Secret Manager) e chaves HMAC que são armazenadas em Secret Manager via `modules/secret_manager`.
   - Instancia o Artifact Registry (`modules/artifactory`) e os módulos de `cloud_run_job`, `lakehouse`, `workflow` e `trigger`.
   - Os `locals` definem variáveis comuns (datasets, buckets, PROJECT_ID, REGION e secrets) para serem injetadas em todos os jobs.

2. **Camada de dados (`modules/lakehouse`)**
   - Cria buckets para recepção/bronze/silver/gold (GCS) e datasets (BigQuery) com nomes parametrizados via `tfvars`.
   - Tabelas padrão:
     - `system.tb_parametro`: tabela gerenciada usada para armazenar parâmetros e cumprida via `modules/managed_table`.
     - `tb_externa_exemplo`: tabela externa apontando para arquivos Parquet no bucket bronze (usa `modules/external_table` que gera um arquivo dummy via `gcloud storage cp` antes da criação da tabela).
     - `tb_gerenciada_exemplo`: tabela gerenciada de exemplo no dataset bronze criada também com `modules/managed_table`.
   - Os módulos `external_table` e `managed_table` oferecem opções de particionamento, clustering, secrets e proteção contra deleção.

3. **Jobs (`001_jobs/`)**
   - Contêm o `Dockerfile` baseado em `python:3.9-slim` e o conjunto de dependências (`requirements.txt`).
   - Exemplo real: `000_sample/main.py` gera pandas DataFrames com dados fictícios e grava no BigQuery. Ele usa variáveis de ambiente definidas pela infraestrutura (`PROJECT_ID`, `BRONZE_DATASET_ID`, etc.).
   - Módulo utilitário `shared/parameter_handler.py` manipula a tabela `system.tb_parametro` (obter, criar ou atualizar parâmetros JSON com queries tipadas).

4. **Orquestração (`002_orquestration/` + módulos `workflow` e `trigger`)**
   - `002_orquestration/001_sample_workflow.yaml`: fluxo simples que chama o Cloud Run Job `teste-job-tf-v3` via a API `googleapis.run.v1.namespaces.jobs.run`.
   - Módulo `modules/workflow` injeta esse YAML via `templatefile`, permitindo parametrizar `project_id`, `region`, labels e service account.
   - Módulo `modules/trigger` cria Cloud Scheduler jobs apontando para workflows ou Cloud Run Jobs (definido por `target_type`). Ele usa `oauth_token` e `http_target` para acionar os serviços.

5. **Utilitários de pipeline (`999_cicd/`)**
   - `00_create_project.bash`: guia a criação de um novo projeto GCP, vincula faturamento e cria o bucket que servirá de backend do Terraform.
   - `01_deploy.bash`: roda todo o deploy (build/push Docker e `terraform apply`) a partir de uma branch e ambiente definidos.

## Requisitos e ambiente (aplicação Linux/baseline)

- **Sistema operacional**: Linux com Bash (`bash` é usado em todos os scripts, incluindo hooks e provisioners do Terraform). Recomenda-se Ubuntu ou Debian para compatibilidade com `gcloud`, `docker` e `terraform`.
- **Ferramentas mínimas** (versões mínimas compatíveis com 2025):
  1. [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install) autenticado (`gcloud auth login` / `gcloud auth application-default login`).
  2. [Docker Engine](https://docs.docker.com/engine/install) (usuário adicionado ao grupo `docker`).
  3. [Terraform CLI](https://developer.hashicorp.com/terraform/downloads).
  4. Python 3.9+ e `pip` (preferível 3.11, mas compatível com 3.9, já que a imagem Docker base é `python:3.9-slim`).
- **Instalação local do Python**:
  ```bash
  python -m pip install --upgrade pip
  pip install -r 001_jobs/requirements.txt
  ```
- **Variáveis de ambiente adicionais** (para execução local):
  ```bash
  export PROJECT_ID=<id-do-projeto>
  export BRONZE_DATASET_ID=<nome-bronze>
  export SILVER_DATASET_ID=<nome-silver>
  export GOLD_DATASET_ID=<nome-gold>
  export REGION=<região>
  ```

## Configuração dos ambientes (`inventories/`)

- `inventories/env/<ambiente>.env`: define as variáveis `TF_VAR_*` usadas pelo deploy (`project_id`, `region`, `artifact_registry_name`, nomes de imagens). Preencha o `TF_VAR_project_id` e mantenha o restante consistente.
- `inventories/tfvars/<ambiente>.tfvars`: mapeia datasets e buckets (nome base). Você deve completar os sufixos (ex: `bucket-bronze-layer-<sufixo>`) quando aplicar.
- `inventories/backend/<ambiente>.conf`: configura o bucket do Terraform state (`bucket-terraform-tfstate-<project-id>`). Atualize o sufixo para o ID do projeto.
- O `01_deploy.bash` lê essas três pastas para compor o fluxo automático. Ele também exige que a branch exista no `origin` e baixa o conteúdo via `git archive`.

## Como criar/alterar tabelas

1. **Tabelas gerenciadas (BigQuery)**
   - Reutilize o módulo `000_infrastructure/modules/lakehouse/modules/managed_table`.
   - Exemplo de uso em `004_bronze_tb_gerenciada_exemplo.tf` (camada bronze).
   - Personalize `schema` (JSON), `description`, `time_partitioning`, `clustering`, `labels` e `require_partition_filter` conforme o caso.
   - Para impedir exclusão acidental marque `deletion_protection = true`.
   - Se precisar expirar dados, use `expiration_time` em milissegundos desde o epoch.

2. **Tabelas externas**
   - Use `modules/external_table`: precisa de um prefixo válido e cria um arquivo dummy automaticamente (por isso depende do `gcloud storage cp`).
   - Defina `bucket_name`, `table_prefix`, `schema` (se `autodetect = false`), `source_format` (PARQUET/CSV/AVRO), `hive_partitioning_mode` e `require_partition_filter`.
   - Como o Terraform cria/remova o dummy, garanta que o SDK esteja autenticado onde o Terraform é executado.

3. **Tabela de parâmetros (`system.tb_parametro`)**
   - Já criada via `modules/managed_table`. Os scripts podem usar `shared/parameter_handler.py` para ler/criar/atualizar parâmetros com JSON e evitar queries SQL repetidas.
   - Para novos parâmetros, basta chamar `get_or_create_parameter(client, "codigo", {...})` e definir o conteúdo JSON.

## Criando novos scripts de job

1. Coloque o código Python dentro de `001_jobs/<nome_do_job>/` ou `001_jobs/` funcionando como pacote.
2. Sempre consuma variáveis via `os.environ` para manter o código desacoplado. Os nomes já definidos são:
   - `PROJECT_ID`, `REGION`, `BRONZE_DATASET_ID`, `SILVER_DATASET_ID`, `GOLD_DATASET_ID`, `SYSTEM_DATASET_ID`, `RECEPTION_BUCKET`, `BRONZE_BUCKET`, `SILVER_BUCKET`, `GOLD_BUCKET`.
   - Se precisar de secrets extras, anote-os em `locals.common_job_secrets` e defina o secret no Secret Manager.
3. Atualize `001_jobs/requirements.txt` com dependências extras e faça build local para validar (ex: `pip install -r 001_jobs/requirements.txt`).
4. O `Dockerfile` já copia todo o diretório `001_jobs`, então basta manter o novo script dentro dele.
5. Para ativar o job no Terraform:
   ```hcl
   module "meu_job" {
     source                           = "./modules/cloud_run_job"
     name                             = "nome-do-job"
     location                         = var.region
     project_id                       = var.project_id
     service_account_email            = google_service_account.cloud_run_job_service_account.email
     cloud_run_jobs_artifact_image_path = local.cloud_run_jobs_artifact_image_path
     args                             = ["python", "caminho/do/script.py"]
     cpu_limit                        = "1"
     memory_limit                     = "512Mi"
     env_vars                         = concat(local.common_job_env_vars, [{ name = "VAR_EXEMPLO" value = "valor" }])
     secrets                          = local.common_job_secrets
   }
   ```
6. Se o job precisar de secrets novos, use o módulo `modules/secret_manager` para criá-los e referencie em `locals.common_job_secrets` ou no módulo específico.

## Orquestração e gatilhos

- Workflows usam `modules/workflow`. Adicione novos arquivos YAML em `002_orquestration/` e atualize o `workflow_yaml_path` e `template_vars` quando instanciar o módulo.
- Triggers usam `modules/trigger`: escolha `target_type = "workflow"` ou `"cloud_run_job"` e preencha os campos correspondentes (`workflow_name`, `workflow_location` ou `cloud_run_job_name`, `cloud_run_job_location`).
- O Cloud Scheduler dispara via HTTP, portanto a service account usada precisa ter permissão `roles/run.invoker` ou `roles/workflows.invoker`.
- Para novas orquestrações, mantenha o YAML em `002_orquestration/`, use `templatefile` e adicione entradas ao módulo de workflow no Terraform.

## Deploy completo (999_cicd/01_deploy.bash)

1. **Pré-requisitos**: `git`, `docker`, `terraform`, `gcloud` instalados e autenticados; branch disponível em `origin`.
2. Chame o script assim:
   ```bash
   ./999_cicd/01_deploy.bash <nome-da-branch> <ambiente>
   ```
   Exemplo: `./999_cicd/01_deploy.bash dev dev`.
3. O script faz:
   - Validação da existência da branch.
   - Baixa o código via `git archive` para uma pasta temporária.
   - Lê `inventories/env/<ambiente>.env` para injetar `TF_VAR_*`.
   - Build/push da imagem Docker (`001_jobs`) para o Artifact Registry (usa o diretório baixado).
   - Executa `terraform init -backend-config=inventories/backend/<ambiente>.conf` e `terraform apply -auto-approve -var-file=inventories/tfvars/<ambiente>.tfvars`.
4. Basta garantir que o bucket do backend (ex: `bucket-terraform-tfstate-<project-id>`) exista antes de rodar o deploy (`00_create_project.bash` cria automaticamente).

## Criando o projeto no GCP (`999_cicd/00_create_project.bash`)

- Script interativo que:
  1. Checa `gcloud` e autenticação.
  2. Pergunta o nome do projeto, procura existências e, se não existir, gera um ID.
  3. Solicita vincular uma conta de faturamento (listar e escolher).
  4. Cria o bucket `gs://bucket-terraform-tfstate-<project-id>` que será usado no backend do Terraform.
- Ideal para equipes que ainda não têm projeto GCP ou bucket de estado.

## Testes e execuções locais

- Para validar o job sem empacotar:
  ```bash
  export PROJECT_ID=seu-projeto
  export BRONZE_DATASET_ID=bronze_layer
  python 001_jobs/000_sample/main.py
  ```
- Use o `parameter_handler` para testar leitura/gravação de parâmetros do BigQuery:
  ```python
  from google.cloud import bigquery
  from shared.parameter_handler import get_or_create_parameter

  client = bigquery.Client(project="meu-projeto")
  param = get_or_create_parameter(client, "meu_param", {"foo": "bar"}, "system_layer")
  ```
- Para rodar testes automatizados (caso adicione): execute `pytest` dentro de `001_jobs` após instalar o `requirements-dev` (já incluídos no `requirements.txt`).

## Dicas de manutenção

1. **Atualize `001_jobs/requirements.txt`** sempre que adicionar dependências aos jobs. O Docker usa esse arquivo para instalar libs.
2. **Documente novos parâmetros** na tabela `system.tb_parametro` e atualize `shared/parameter_handler.py` se mudar a estrutura JSON.
3. **Use labels e descrições** nos módulos Terraform para facilitar auditoria (`labels` existe nos módulos Cloud Run, Workflows e Tables).
4. **Revise os arquivos `.env`, `.tfvars` e `backend`** antes de qualquer deploy para não sobrescrever recursos de outro ambiente.
5. **Versões de imagem** no Artifact Registry seguem o padrão `${IMAGE_NAME}:latest` no deploy automatizado; para usar tags fixas, ajuste `01_deploy.bash` e o `module "cloud_run_job"`.

---

Se precisar de mais exemplos (ex: adaptando um workflow, adicionando um novo trigger ou criando uma tabela particionada específica), basta estender os módulos existentes mantendo o padrão de parâmetros e o uso de `templatefile`/`locals`. Mantendo esse README atualizado, toda nova adição fica fácil de entender e replicar.
