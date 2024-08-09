#!/bin/bash

# Variáveis
PROJECT_DIR="/home/ubuntu/django_basic"
REPO_URL="git@github.com:megacomputerman/django_basic.git"
VENV_DIR="$PROJECT_DIR/positrom-vm"
DOMAIN="ec2-3-135-187-11.us-east-2.compute.amazonaws.com"
UWSGI_INI="$PROJECT_DIR/uwsgi.ini"
NGINX_CONF="/etc/nginx/sites-available/mysite_nginx.conf"
UWSGI_PARAMS="$PROJECT_DIR/uwsgi_params"
SOCKET_FILE="$PROJECT_DIR/mysite.sock"

# Função para exibir mensagens
function info {
    echo -e "\n\e[1;32m$1\e[0m\n"
}

# 1. Preparando o ambiente
info "Instalando pacotes necessários..."
sudo apt-get update
#sudo apt-get install -y python3-venv python3.6-dev build-essential libssl-dev libffi-dev python-dev nginx

# 2. Criar ambiente virtual
info "Criando ambiente virtual..."
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

# 3. Clonar repositório
info "Clonando repositório..."
git clone $REPO_URL

# 4. Instalar dependências do Python
info "Instalando dependências do Python..."
pip install -r $PROJECT_DIR/requirements.txt

# 5. Configurar e coletar arquivos estáticos
info "Configurando e coletando arquivos estáticos..."
cd $PROJECT_DIR
python manage.py collectstatic --noinput
python manage.py migrate
python manage.py createsuperuser



info "Criando arquivo de configuração do uWSGI..."
cat <<EOL > $UWSGI_INI
[uwsgi]
chdir           = $PROJECT_DIR
module          = positrom2.wsgi
home            = $VENV_DIR
master          = true
processes       = 10
socket          = $SOCKET_FILE
vacuum          = true
chmod-socket    = 666
EOL

# 7. Configurar NGINX
info "Configurando NGINX..."

# Criar arquivo uwsgi_params
cat <<EOL > $UWSGI_PARAMS
uwsgi_param  QUERY_STRING       \$query_string;
uwsgi_param  REQUEST_METHOD     \$request_method;
uwsgi_param  CONTENT_TYPE       \$content_type;
uwsgi_param  CONTENT_LENGTH     \$content_length;
uwsgi_param  REQUEST_URI        \$request_uri;
uwsgi_param  PATH_INFO          \$document_uri;
uwsgi_param  DOCUMENT_ROOT      \$document_root;
uwsgi_param  SERVER_PROTOCOL    \$server_protocol;
uwsgi_param  REQUEST_SCHEME     \$scheme;
uwsgi_param  HTTPS              \$https if_not_empty;
uwsgi_param  REMOTE_ADDR        \$remote_addr;
uwsgi_param  REMOTE_PORT        \$remote_port;
uwsgi_param  SERVER_PORT        \$server_port;
uwsgi_param  SERVER_NAME        \$server_name;
EOL

# Criar configuração do NGINX
sudo tee $NGINX_CONF > /dev/null <<EOL
upstream django {
    server unix://$SOCKET_FILE;
}

server {
    listen 8000;
    server_name $DOMAIN;
    charset utf-8;

    client_max_body_size 75M;

    location /media {
        alias $PROJECT_DIR/media;
    }

    location /static {
        alias $PROJECT_DIR/static;
    }

    location / {
        uwsgi_pass django;
        include $UWSGI_PARAMS;
    }
}
EOL

# Criar symlink para sites-enabled
info "Criando symlink para sites-enabled..."
sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/

# Reiniciar NGINX
info "Reiniciando NGINX..."
sudo /etc/init.d/nginx restart

# 8. Testar e rodar o uWSGI
info "Rodando o uWSGI usando Unix sockets..."
uwsgi --socket $SOCKET_FILE --module positrom2.wsgi --chmod-socket=666

info "Configuração concluída com sucesso!"

