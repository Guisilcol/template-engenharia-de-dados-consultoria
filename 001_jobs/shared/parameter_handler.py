"""
Parameter Handler Module

Este módulo gerencia parâmetros armazenados na tabela system.tb_parametro do BigQuery.
Schema da tabela:
- uuid: STRING (gerado automaticamente)
- codigo_parametro: STRING (chave única do parâmetro)
- parametro: JSON (dados do parâmetro)
- datahora_criacao: TIMESTAMP (gerado automaticamente)
- datahora_alteracao: TIMESTAMP (atualizado automaticamente)
"""

import json
from typing import Dict, Any
from google.cloud.bigquery import Client, QueryJobConfig, ScalarQueryParameter


def get_parameter(
    client: "Client",
    parameter_code: "str",
    dataset_id: "str",
    table: "str" = "tb_parametro",
) -> "Dict[str, Any]":
    query = f"""
        SELECT parametro
        FROM `{dataset_id}.{table}`
        WHERE codigo_parametro = @parameter_code
        LIMIT 1
    """

    job_config = QueryJobConfig(
        query_parameters=[
            ScalarQueryParameter("parameter_code", "STRING", parameter_code)
        ]
    )

    # Executa a query
    query_job = client.query(query, job_config=job_config)
    results = query_job.result()

    # Converte o resultado para dicionário
    for row in results:
        return json.loads(row.parametro) if row.parametro else None

    raise ValueError(
        f"Parâmetro '{parameter_code}' não encontrado na tabela "
        f"`{dataset_id}.{table}`"
    )


def get_or_create_parameter(
    client: "Client",
    parameter_code: "str",
    default_parameter: "Dict[str, Any]",
    dataset_id: "str",
    table: "str" = "tb_parametro",
) -> "Dict[str, Any]":
    # Tenta buscar o parâmetro existente
    
    try:
        existing_param = get_parameter(client, parameter_code, dataset_id, table)
        return existing_param
    except ValueError:
        pass

    # Se não existe, cria um novo
    parameter = json.dumps(default_parameter, ensure_ascii=False)

    insert_query = f"""
        INSERT INTO `{dataset_id}.{table}` 
        (codigo_parametro, parametro)
        VALUES (@parameter_code, PARSE_JSON(@parameter))
    """

    job_config = QueryJobConfig(
        query_parameters=[
            ScalarQueryParameter("parameter_code", "STRING", parameter_code),
            ScalarQueryParameter("parameter", "STRING", parameter),
        ]
    )

    # Executa o insert
    query_job = client.query(insert_query, job_config=job_config)
    query_job.result()  # Aguarda conclusão

    # Retorna o parâmetro recém-criado
    return json.loads(parameter)


def update_parameter(
    client: "Client",
    parameter_code: "str",
    parameter: "Dict[str, Any]",
    dataset_id: "str",
    table: "str" = "tb_parametro",
) -> "None":
    # Verifica se o parâmetro existe (get_parameter já lança ValueError se não existir)
    get_parameter(client, parameter_code, dataset_id, table)

    # Atualiza o parâmetro
    parameter_json = json.dumps(parameter, ensure_ascii=False)

    update_query = f"""
        UPDATE `{dataset_id}.{table}`
        SET 
            parametro = PARSE_JSON(@parameter),
            datahora_alteracao = CURRENT_TIMESTAMP()
        WHERE codigo_parametro = @parameter_code
    """

    job_config = QueryJobConfig(
        query_parameters=[
            ScalarQueryParameter("parameter_code", "STRING", parameter_code),
            ScalarQueryParameter("parameter", "STRING", parameter_json),
        ]
    )

    # Executa o update
    query_job = client.query(update_query, job_config=job_config)
    query_job.result()  # Aguarda conclusão

    # Verifica se alguma linha foi atualizada
    if query_job.num_dml_affected_rows == 0:
        raise ValueError(
            f"Falha ao atualizar o parâmetro '{parameter_code}'. "
            f"Nenhuma linha foi afetada na tabela `{dataset_id}.{table}`"
        )
