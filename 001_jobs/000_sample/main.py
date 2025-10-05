import os
import uuid
from datetime import datetime
import pandas as pd
from google.cloud import bigquery

# Get environment variables
project_id = os.environ.get("PROJECT_ID")
bronze_layer = os.environ.get("BRONZE_DATASET_ID")
table_id = f"{bronze_layer}.tb_gerenciada_exemplo"

print(f"Project ID: {project_id}")
print(f"Table ID: {table_id}")

# Initialize BigQuery client
print('Initializing BigQuery client...')
client = bigquery.Client(project=project_id)

print('Generating sample data...')
# Generate sample data
data = [
    {"ID": str(uuid.uuid4()), "data": datetime.now().isoformat()},
    {"ID": str(uuid.uuid4()), "data": datetime.now().isoformat()},
]

# Create a Pandas DataFrame
df = pd.DataFrame(data)

# Define table schema
schema = [
    bigquery.SchemaField("ID", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("data", "STRING", mode="REQUIRED"),
]

# Configure the load job
job_config = bigquery.LoadJobConfig(
    schema=schema,
    write_disposition="WRITE_APPEND",  # Append to the table
)

# Load data into BigQuery
print('Loading data into BigQuery...')
job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
job.result()  # Wait for the job to complete

print(f"Loaded {len(df)} rows into {table_id}.")
