import datetime
import json
import os
import sys
from typing import Dict, List, Tuple

import requests
from google.cloud import storage
from google.cloud.bigquery import Client

import shared.parameter_handler as ph


class APIDataExtractor:
    """
    Extrai dados de uma API e armazena no Google Cloud Storage (GCS) em formato JSONL.
    Gerencia o controle de execução através de parâmetros armazenados no BigQuery.
    """

    # Constantes
    DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
    MAX_BATCH_SIZE = 50

    def __init__(
        self,
        client: Client,
        system_dataset_id: str,
        parameter_code: str,
        url: str,
        user: str,
        password: str,
        bucket: str,
        prefix: str,
    ):
        """
        Inicializa o extrator de dados da API.

        Args:
            client: Cliente do BigQuery
            system_dataset_id: ID do dataset onde os parâmetros são armazenados
            parameter_code: Código do parâmetro para controle de execução
            url: URL da API
            user: Usuário para autenticação na API
            password: Senha para autenticação na API
            bucket: Nome do bucket GCS
            prefix: Prefixo para os arquivos no GCS
        """
        self.client = client
        self.system_dataset_id = system_dataset_id
        self.parameter_code = parameter_code
        self.url = url
        self.user = user
        self.password = password
        self.bucket = bucket
        self.prefix = prefix
        self.storage_client = storage.Client()

    def create_datetime_range(
        self, start: datetime.datetime, end: datetime.datetime
    ) -> List[Tuple[datetime.datetime, datetime.datetime]]:
        """
        Cria uma lista de tuplas com intervalos diários entre start e end.

        Args:
            start: Data e hora inicial
            end: Data e hora final

        Returns:
            Lista de tuplas (início, fim) representando intervalos diários
        """
        date_ranges = []
        current = start

        while current <= end:
            start_of_day = current.replace(hour=0, minute=0, second=0, microsecond=0)

            if current.date() == end.date():
                end_of_day = end
            else:
                end_of_day = current.replace(
                    hour=23, minute=59, second=59, microsecond=999999
                )

            date_ranges.append((start_of_day, end_of_day))
            current += datetime.timedelta(days=1)

        return date_ranges

    def extract_data_from_api(
        self, start: datetime.datetime, end: datetime.datetime
    ) -> Dict:
        """
        Extrai dados da API para o intervalo de datas especificado.

        Args:
            start: Data e hora inicial
            end: Data e hora final

        Returns:
            Resposta da API em formato JSON

        Raises:
            requests.exceptions.HTTPError: Se a requisição falhar
        """
        body = {
            "dataInicial": start.strftime(self.DATETIME_FORMAT),
            "dataFinal": end.strftime(self.DATETIME_FORMAT),
        }

        print(f"  > Fazendo requisição: {body['dataInicial']} até {body['dataFinal']}")

        response = requests.post(
            self.url,
            json=body,
            auth=(self.user, self.password),
            timeout=300,
        )

        response.raise_for_status()
        return response.json()

    def save_to_gcs(self, data: List[Dict], filename: str) -> None:
        """
        Salva dados no Google Cloud Storage em formato JSONL.

        Args:
            data: Lista de dicionários a serem salvos
            filename: Nome do arquivo no GCS
        """
        if not data:
            print("  > Nenhum dado para salvar")
            return
        
        jsonl_content = "\n".join(
            [json.dumps(record, ensure_ascii=False) for record in data]
        )

        bucket = self.storage_client.bucket(self.bucket)
        blob = bucket.blob(filename)

        blob.upload_from_string(jsonl_content, content_type="application/jsonl")

        print(
            f"  > Arquivo salvo: gs://{self.bucket}/{filename} ({len(data)} registros)"
        )

    def update_last_datetime_parameter(self, datetime_value: datetime.datetime) -> None:
        """
        Atualiza o parâmetro last_datetime no BigQuery.

        Args:
            datetime_value: Novo valor para last_datetime
        """
        print("  > Atualizando parâmetro 'last_datetime' no BigQuery...")

        ph.update_parameter(
            client=self.client,
            parameter_code=self.parameter_code,
            parameter={"last_datetime": datetime_value.strftime(self.DATETIME_FORMAT)},
            dataset_id=self.system_dataset_id,
        )

        print(f"  > Parâmetro atualizado para: {datetime_value}")

    def process_batch(self, data_batch: List[Dict]) -> None:
        """
        Processa e salva um lote de dados no GCS e atualiza o parâmetro.

        Args:
            data_batch: Lote de dados a ser processado
            end_datetime: Data e hora final do intervalo processado
        """
        timestamp = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S_%f")
        filename = f"{self.prefix}/data_{timestamp}.jsonl"

        self.save_to_gcs(data_batch, filename)

    def run(self) -> None:
        """
        Executa o processo completo de extração de dados da API.

        O processo:
        1. Carrega o último datetime processado do BigQuery
        2. Cria intervalos diários até a data atual
        3. Extrai dados para cada intervalo
        4. Acumula dados até atingir o limite de 252 MB
        5. Salva no GCS e atualiza o parâmetro de controle
        6. Salva dados restantes ao final
        """
        print("> Iniciando job de ingestão de API...")
        print("> Carregando parâmetros do BigQuery...")

        params = ph.get_or_create_parameter(
            client=self.client,
            parameter_code=self.parameter_code,
            default_parameter={"last_datetime": "2021-12-31 23:59:59"},
            dataset_id=self.system_dataset_id,
        )

        print(f"> Parâmetros carregados: {params}")

        last_datetime_str = params.get("last_datetime")
        if not last_datetime_str:
            raise ValueError("Parâmetro 'last_datetime' não encontrado")

        last_datetime = datetime.datetime.strptime(
            last_datetime_str, self.DATETIME_FORMAT
        )
        # Adiciona 1 segundo para evitar reprocessamento do último registro
        last_datetime += datetime.timedelta(seconds=1)
        current_datetime = datetime.datetime.now()

        print(f"> Última execução tratada: {last_datetime}")
        print(f"> Data/hora atual: {current_datetime}")

        datetime_ranges = self.create_datetime_range(last_datetime, current_datetime)
        print(f"> Total de intervalos a processar: {len(datetime_ranges)}")

        if not datetime_ranges:
            print("> Nenhum intervalo para processar. Job finalizado.")
            return

        all_data = []
        for idx, (start, end) in enumerate(datetime_ranges, 1):
            print(
                f"\n> Processando intervalo {idx}/{len(datetime_ranges)}: "
                f"{start} até {end}"
            )
            
            data = self.extract_data_from_api(start, end)

            if data.get("dados"):
                all_data.append(data)
                print(f"  > Dados extraídos: {len(data['dados'])} registros")
            else:
                print("  > Nenhum dado retornado para este intervalo")

            # Salva se atingir o limite ou for o último intervalo
            should_save = len(all_data) >= self.MAX_BATCH_SIZE
            is_last_interval = idx == len(datetime_ranges)

            if (should_save and all_data) or (is_last_interval and all_data):
                print("  > Salvando no GCS...")
                self.process_batch(all_data)
                self.update_last_datetime_parameter(end)
                all_data = []
                
        print("\n> Job finalizado com sucesso!")


def get_required_env(var_name: str) -> str:
    """
    Obtém uma variável de ambiente obrigatória.

    Args:
        var_name: Nome da variável de ambiente

    Returns:
        Valor da variável de ambiente

    Raises:
        ValueError: Se a variável não estiver definida
    """
    value = os.getenv(var_name)
    if not value:
        raise ValueError(f"Variável de ambiente '{var_name}' não está definida")
    return value


def main() -> None:
    """
    Função principal que configura e executa o extrator de dados da API.
    """
    try:
        # Carrega configurações das variáveis de ambiente
        config = {
            "system_dataset_id": get_required_env("SYSTEM_DATASET_ID"),
            "parameter_code": get_required_env("PARAMETER_CODE"),
            "api_url": get_required_env("API_URL"),
            "api_user": get_required_env("API_USER"),
            "api_password": get_required_env("API_PASSWORD"),
            "gcs_bucket": get_required_env("GCS_BUCKET"),
            "gcs_prefix": get_required_env("GCS_PREFIX"),
            "project_id": get_required_env("GCP_PROJECT_ID"),
        }

        # Inicializa o cliente do BigQuery
        bq_client = Client(project=config["project_id"])

        # Cria e executa o extrator
        extractor = APIDataExtractor(
            client=bq_client,
            system_dataset_id=config["system_dataset_id"],
            parameter_code=config["parameter_code"],
            url=config["api_url"],
            user=config["api_user"],
            password=config["api_password"],
            bucket=config["gcs_bucket"],
            prefix=config["gcs_prefix"],
        )

        extractor.run()

    except ValueError as e:
        print(f"Erro de configuração: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Erro durante a execução: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
