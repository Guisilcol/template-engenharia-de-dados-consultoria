FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .

# Instalar dependências
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8050

# Sem CMD/ENTRYPOINT - será especificado completamente no Cloud Run Service via Terraform
