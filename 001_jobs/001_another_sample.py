import datetime
import os
import requests
import json
from google.cloud import storage
from typing import List, Tuple, Dict
from google.cloud.bigquery import Client
import shared.parameter_handler as ph
import sys

"""
class App:

    def parse_date(self, date_str: 'str') -> datetime.datetime:
        Parse date string in format YYYY-MM-DD HH:MM:SS
        return datetime.datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
    
    def get_env(self, var_name: 'str', default: 'str | None' = None) -> 'str':
    Get environment variable or raise error if not set
        value = os.getenv(var_name)
        if value is None:
            if default is not None:
                return default
            raise ValueError(f'Environment variable {var_name} is not set and no default provided')
        return value
    
    def generate_date_range(self, start: datetime.datetime, end: datetime.datetime) -> List[datetime.datetime]:
        Generate list of dates, one day at a time
        dates = []
        current = start
        while current <= end:
            dates.append(current)
            current += datetime.timedelta(days=1)
        return dates
    
    def extract_data_from_api(self, url: str, user: str, password: str, date: datetime.datetime) -> Dict[str, Any]:
        Extract data from API for a specific day
        # Define start and end of the day
        data_inicial = date.strftime("%Y-%m-%d 00:00:00")
        data_final = date.strftime("%Y-%m-%d 23:59:59")
        
        body = {
            "dataInicial": data_inicial,
            "dataFinal": data_final
        }
        
        print(f'  > Fazendo requisição para: {data_inicial} até {data_final}')
        
        try:
            response = requests.post(
                url,
                json=body,
                auth=(user, password),
                timeout=300  # 5 minutes timeout
            )
            response.raise_for_status()
            
            data = response.json()
            return data
            
        except requests.exceptions.RequestException as e:
            print(f'  > ERRO na requisição: {e}')
            raise
    
    def save_to_jsonl(self, data: List[Dict[str, Any]], bucket_name: str, prefix: str, date: datetime.datetime) -> str:
        Save data to GCS as JSONL file
        if not data:
            print(f'  > Nenhum dado para salvar')
            return None
        
        # Generate filename with timestamp
        timestamp = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S_%f")
        filename = f"{prefix}/data_{timestamp}.jsonl"
        
        print(f'  > Salvando arquivo: gs://{bucket_name}/{filename}')
        
        
        # Create JSONL content
        jsonl_content = '\n'.join([json.dumps(record, ensure_ascii=False) for record in data])
        
        # Upload to GCS
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(filename)
        
        blob.upload_from_string(
            jsonl_content,
            content_type='application/jsonl'
        )
        
        print(f'  > Arquivo salvo com sucesso: {len(data)} registros')
        return filename
    
    def run(self) -> 'None':
        print('> Iniciando job de ingestão de API...')
        print('='*80)

        # Get environment variables
        start_date = self.get_env("START_DATE")
        default_end_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S").split(' ')[0] + ' 23:59:59'
        end_date = self.get_env("END_DATE", default_end_date)
        url = self.get_env("API_URL")
        user = self.get_env("API_USER")
        password = self.get_env("API_PASSWORD")
        bucket = self.get_env("GCS_BUCKET")
        prefix = self.get_env("GCS_PREFIX")  # e.g., "api/br/bmgfoods/vendas_devol"

        print('> Variáveis de ambiente carregadas:')
        print(f"  START_DATE: {start_date}")
        print(f"  END_DATE: {end_date}")
        print(f"  API_URL: {url}")
        print(f"  API_USER: {user}")
        print(f"  GCS_BUCKET: {bucket}")
        print(f"  GCS_PREFIX: {prefix}")
        print('='*80)

        # Parse dates
        print('> Convertendo datas...')
        start = self.parse_date(start_date)
        end = self.parse_date(end_date)
        
        print(f'  Data inicial: {start}')
        print(f'  Data final: {end}')
        print('='*80)

        # Generate date range (one day at a time)
        dates = self.generate_date_range(start, end)
        print(f'> Total de dias a processar: {len(dates)}')
        print('='*80)

        # Process each day
        total_records = 0
        successful_days = 0
        failed_days = 0
        
        for idx, date in enumerate(dates, 1):
            print(f'\n> Processando dia {idx}/{len(dates)}: {date.strftime("%Y-%m-%d")}')
            
            try:
                # Extract data from API
                data = self.extract_data_from_api(url, user, password, date)

                # Save to GCS
                if data['dados'] != []:
                    filename = self.save_to_jsonl(data, bucket, prefix, date)
                    total_records += len(data)
                    successful_days += 1
                else:
                    print(f'  > Sem dados para o dia {date.strftime("%Y-%m-%d")}')
                    successful_days += 1
                    
            except Exception as e:
                print(f'  > ERRO ao processar dia {date.strftime("%Y-%m-%d")}: {e}')
                failed_days += 1
                # Continue processing next days
                continue
        
        # Summary
        print('\n' + '='*80)
        print('> RESUMO DA EXECUÇÃO')
        print(f'  Total de dias processados: {len(dates)}')
        print(f'  Dias com sucesso: {successful_days}')
        print(f'  Dias com erro: {failed_days}')
        print(f'  Total de registros extraídos: {total_records}')
        print('='*80)
        print('> Job finalizado!')
"""


class App:
    def __init__(
        self,
        client: "Client",
        system_dataset_id: "str",
        parameter_code: "str",
        url: "str",
        user: "str",
        password: "str",
        bucket: "str",
        prefix: "str",
    ):
        self.client = client
        self.system_dataset_id = system_dataset_id
        self.parameter_code = parameter_code
        self.url = url
        self.user = user
        self.password = password
        self.bucket = bucket
        self.prefix = prefix

    def create_datetime_range(
        self, start: "datetime.datetime", end: "datetime.datetime"
    ) -> "List[Tuple[datetime.datetime, datetime.datetime]]":
        """
        Cria uma lista de tuplas com intervalos diários entre start e end,
        começando à meia-noite e terminando às 23:59:59 de cada dia.
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

    def get_list_size_mb(self, target_list: "list") -> "int":
        total_size_bytes = sys.getsizeof(target_list)
        for item in target_list:
            total_size_bytes += sys.getsizeof(item)
        
        size_in_mb = total_size_bytes / (1024 * 1024)
        return int(size_in_mb)

    def extract_data_from_api(
        self, start: "datetime.datetime", end: "datetime.datetime"
    ) -> "List[Dict]":
        """
        Extrai dados da API para o intervalo de datas especificado.
        """

        body = {
            "dataInicial": start.strftime("%Y-%m-%d %H:%M:%S"),
            "dataFinal": end.strftime("%Y-%m-%d %H:%M:%S"),
        }

        print(
            f"  > Fazendo requisição para: {body['dataInicial']} até {body['dataFinal']}"
        )

        response = requests.post(
            self.url,
            json=body,
            auth=(self.user, self.password),
        )

        response.raise_for_status()
        data = response.json()
        return data

    def run(self):
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
        if last_datetime_str is None:
            raise ValueError("Parâmetro 'last_datetime' não encontrado nos parâmetros")

        last_datetime = datetime.datetime.strptime(
            last_datetime_str, "%Y-%m-%d %H:%M:%S"
        )
        current_datetime = datetime.datetime.now()

        print(f">> last_datetime: {last_datetime}")

        datetime_ranges = self.create_datetime_range(last_datetime, current_datetime)

        print(f"> Total de intervalos a processar: {len(datetime_ranges)}")


        # Extrai dados para cada intervalo. 
        # Quando a lista de dados atingir 252 MB OU não houver mais intervalos, salva no GCS.
        # Antes de anexar na lista, verifica se a chave "dados" não é um array vazio, se for, não anexa.
        # Toda vez que salvar no GCS, atualiza o parâmetro last_datetime no BigQuery com a data final do intervalo salvo.
        
        all_data = []
        current_last_datetime = last_datetime

        for idx, (start, end) in enumerate(datetime_ranges, 1):
            print(f"\n> Processando intervalo {idx}/{len(datetime_ranges)}: {start} até {end}")

            try:
                data = self.extract_data_from_api(start, end)
                
                if data.get("dados"):
                    all_data.extend(data["dados"])
                    print(f"  > Dados extraídos: {len(data['dados'])} registros")
                else:
                    print("  > Nenhum dado retornado para este intervalo")

                size_mb = self.get_list_size_mb(all_data)
                print(f"  > Tamanho acumulado dos dados: {size_mb} MB")

                # Se a lista atingir 252 MB, salva no GCS e atualiza o parâmetro
                if size_mb >= 252:
                    print("  > Tamanho limite atingido, salvando no GCS...")
                    timestamp = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S_%f")
                    filename = f"{self.prefix}/data_{timestamp}.jsonl"

                    jsonl_content = '\n'.join([json.dumps(record, ensure_ascii=False) for record in all_data])

                    storage_client = storage.Client()
                    bucket = storage_client.bucket(self.bucket)
                    blob = bucket.blob(filename)

                    blob.upload_from_string(
                        jsonl_content,
                        content_type='application/jsonl'
                    )

                    print(f"  > Arquivo salvo com sucesso: gs://{self.bucket}/{filename} com {len(all_data)} registros")

                    # Atualiza o parâmetro last_datetime
                    print(f"  > Atualizando parâmetro 'last_datetime' no BigQuery...")
                    current_last_datetime = end
                    ph.update_parameter(
                        client=self.client,
                        parameter_code=self.parameter_code,
                        parameter={"last_datetime": current_last_datetime.strftime("%Y-%m-%d %H:%M:%S")},
                        dataset_id=self.system_dataset_id
                    )
                    
                    print(f"  > Parâmetro 'last_datetime' atualizado para: {current_last_datetime}")

                    # Limpa a lista de dados
                    all_data = []

            except Exception as e:
                print(f"  > ERRO ao processar intervalo {start} até {end}: {e}")
                continue

        # Se ainda houver dados acumulados, salva no GCS
        if all_data:
            print("  > Salvando dados restantes no GCS...")
            timestamp = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S_%f")
            filename = f"{self.prefix}/data_{timestamp}.jsonl"

            jsonl_content = '\n'.join([json.dumps(record, ensure_ascii=False) for record in all_data])

            storage_client = storage.Client()
            bucket = storage_client.bucket(self.bucket)
            blob = bucket.blob(filename)

            blob.upload_from_string(
                jsonl_content,
                content_type='application/jsonl'
            )

            print(f"  > Arquivo salvo com sucesso: gs://{self.bucket}/{filename} com {len(all_data)} registros")

            # Atualiza o parâmetro last_datetime
            current_last_datetime = end
            print(f"  > Atualizando parâmetro 'last_datetime' no BigQuery...")
            ph.update_parameter(
                client=self.client,
                parameter_code=self.parameter_code,
                parameter={"last_datetime": current_last_datetime.strftime("%Y-%m-%d %H:%M:%S")},
                dataset_id=self.system_dataset_id
            )

            print(f"  > Parâmetro 'last_datetime' atualizado para: {current_last_datetime}")

            # Limpa a lista de dados
            all_data = []

def main():
    # Configurações iniciais
    system_dataset_id = os.getenv("SYSTEM_DATASET_ID")
    parameter_code = os.getenv("PARAMETER_CODE")
    api_url = os.getenv("API_URL")
    api_user = os.getenv("API_USER")
    api_password = os.getenv("API_PASSWORD")
    gcs_bucket = os.getenv("GCS_BUCKET")
    gcs_prefix = os.getenv("GCS_PREFIX")
    project_id = os.getenv("GCP_PROJECT_ID")


    # Inicializa o cliente do BigQuery
    bq_client = Client(project=project_id)

    app = App(
        client=bq_client,
        system_dataset_id=system_dataset_id,
        parameter_code=parameter_code,
        url=api_url,
        user=api_user,
        password=api_password,
        bucket=gcs_bucket,
        prefix=gcs_prefix,
    )

    app.run()

if __name__ == "__main__":
    main()
