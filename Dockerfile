# Usar a imagem oficial do Python como base
FROM python:3.9-slim

# Configurar o diretório de trabalho
WORKDIR /positrom

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar os arquivos do projeto para o contêiner
COPY . /positrom

# Instalar as dependências
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Executar as migrações do banco de dados
RUN python manage.py migrate

# Expor a porta que a aplicação usará
EXPOSE 8000

# Comando para rodar a aplicação usando Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "positrom2.wsgi:application"]
