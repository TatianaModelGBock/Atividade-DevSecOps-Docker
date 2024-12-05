#!/bin/bash

# Atualiza os pacotes disponíveis
apt-get update -y

# Instala os pacotes necessários
apt-get install -y ca-certificates curl gnupg

# Cria o diretório para as chaves GPG, se não existir
mkdir -p /etc/apt/keyrings

# Baixa a chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Adiciona o repositório do Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Atualiza novamente os pacotes para incluir o novo repositório
apt-get update -y

# Instala o Docker e seus componentes
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Inicia o serviço Docker e troca suas permissões
systemctl start docker
sudo usermod -aG docker ubuntu
systemctl enable docker

# Testa a instalação do Docker e registra no log
docker --version >> /var/log/user-data.log 2>&1
docker compose version >> /var/log/user-data.log 2>&1


# Instalação do EFS dentro da EC2
sudo apt install nfs-common -y

# Criar ponto de montagem do EFS
sudo mkdir -p /efs


# Montar o EFS usando o EFS Mount Helper com TLS
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-003345c67c89b602b.efs.us-east-1.amazonaws.com:/ /efs

# Acessar o armazenamento EFS
#cd /efs

cat << EOF > docker-compose.yaml
services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
     WORDPRESS_DB_HOST: \${WORDPRESS_DB_HOST}
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${WORDPRESS_DB_NAME}
    volumes:
      - /efs/wordpress:/var/www/html
EOF

# Iniciar o docker compose
cd /
docker compose -p wp up -d
