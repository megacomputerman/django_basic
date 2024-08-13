#!/bin/bash

# Este script instala Docker e Docker Compose em um sistema baseado em Debian/Ubuntu

# Função para verificar se um comando falhou
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erro: $1 falhou."
        exit 1
    fi
}

# Atualizar o índice de pacotes
echo "Atualizando o índice de pacotes..."
sudo apt update
check_command "Atualização do índice de pacotes"

# Instalar pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
check_command "Instalação dos pacotes necessários"

# Adicionar a chave GPG oficial do Docker
echo "Adicionando a chave GPG oficial do Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
check_command "Adição da chave GPG do Docker"

# Adicionar o repositório do Docker
echo "Adicionando o repositório do Docker..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_command "Adição do repositório do Docker"

# Atualizar o índice de pacotes novamente
echo "Atualizando o índice de pacotes novamente..."
sudo apt update
check_command "Atualização do índice de pacotes"

# Instalar Docker
echo "Instalando Docker..."
sudo apt install -y docker-ce
check_command "Instalação do Docker"

# Verificar a instalação do Docker
echo "Verificando a instalação do Docker..."
sudo systemctl status docker
check_command "Verificação do status do Docker"

# Baixar a versão mais recente do Docker Compose
echo "Baixando Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
check_command "Download do Docker Compose"

# Aplicar permissões de execução ao binário do Docker Compose
echo "Aplicando permissões ao Docker Compose..."
sudo chmod +x /usr/local/bin/docker-compose
check_command "Aplicação de permissões ao Docker Compose"

# Verificar a instalação do Docker Compose
echo "Verificando a instalação do Docker Compose..."
docker-compose --version
check_command "Verificação do Docker Compose"

# Adicionar o usuário atual ao grupo Docker para evitar uso de sudo
echo "Adicionando usuário ao grupo Docker..."
sudo usermod -aG docker ${USER}
check_command "Adição do usuário ao grupo Docker"

echo "Instalação completa. Efetue logout e login novamente para aplicar as mudanças."
