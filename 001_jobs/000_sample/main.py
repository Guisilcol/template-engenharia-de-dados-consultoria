from dataclasses import dataclass
import os
import uuid
from datetime import datetime
import pandas as pd
from google.cloud import bigquery, logging as cloud_logging
import logging


@dataclass
class Args:
    project_id: str
    bronze_layer: str
    table_id: str


@dataclass
class Context:
    args: Args
    logger: logging.Logger
    bq_client: bigquery.Client


def compute_sample_data(ctx: Context) -> pd.DataFrame:
    ctx.logger.info("Generating sample data...")

    data = [
        {"ID": str(uuid.uuid4()), "data": datetime.now().isoformat()},
        {"ID": str(uuid.uuid4()), "data": datetime.now().isoformat()},
    ]

    df = pd.DataFrame(data)
    return df


def write_sample_data(ctx: Context, df: pd.DataFrame):
    ctx.logger.info("Writing sample data to BigQuery...")

    schema = [
        bigquery.SchemaField("ID", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("data", "STRING", mode="REQUIRED"),
    ]

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        write_disposition="WRITE_APPEND",
    )

    job = ctx.bq_client.load_table_from_dataframe(
        df, ctx.args.table_id, job_config=job_config
    )
    job.result()

    ctx.logger.info(f"Loaded {len(df)} rows into {ctx.args.table_id}.")


def run(ctx: Context):
    df = compute_sample_data(ctx)
    write_sample_data(ctx, df)


def main():
    # Set up logging
    logging.basicConfig(level=logging.INFO)
    cloud_logging_client = cloud_logging.handlers.CloudLoggingHandler()
    logger = logging.getLogger()
    logger.addHandler(cloud_logging_client)
    logger.setLevel(logging.INFO)

    # Get environment variables
    project_id = os.environ.get("PROJECT_ID")
    bronze_layer = os.environ.get("BRONZE_DATASET_ID")
    table_id = f"{bronze_layer}.tb_gerenciada_exemplo"

    args = Args(
        project_id=project_id,
        bronze_layer=bronze_layer,
        table_id=table_id,
    )

    # Initialize BigQuery client
    bq_client = bigquery.Client(project=project_id)

    ctx = Context(
        args=args,
        logger=logger,
        bq_client=bq_client,
    )

    run(ctx)


if __name__ == "__main__":
    main()
