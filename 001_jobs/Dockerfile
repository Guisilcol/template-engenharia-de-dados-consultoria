# Use a imagem oficial do Python 3.9 como base
FROM python:3.9-slim

# Define o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copia o arquivo de dependências primeiro para aproveitar o cache do Docker
COPY requirements.txt ./

# Instala as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copia todo o conteúdo do diretório 001_jobs para o diretório de trabalho no contêiner
COPY . .

# O ENTRYPOINT será definido na configuração do Cloud Job
