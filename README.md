# Atividade DevSecOps Docker

## Deploy de Aplicação WordPress na AWS com Docker (Compass uol)

### Descrição do Projeto
> Este projeto visa simplificar e automatizar a implantação de uma aplicação WordPress na AWS, utilizando contêineres Docker para criar uma infraestrutura escalável e confiável. A solução inclui Amazon EFS para armazenamento de arquivos estáticos, Amazon RDS para o banco de dados MySQL e Elastic Load Balancer para gestão eficiente do tráfego. Bem documentado, o projeto é fácil de replicar e adaptar.



-----
###  Acessar o Console da AWS

1. Acesse o **AWS Management Console**.
2. Faça login com suas credenciais (usuário e senha, ou MFA, se configurado).

---

### 1. Configuração da VPC
- **Nome**: vpcwordpress-vpc  
- **Bloco CIDR IPv4**: 10.0.0.0/16  

**No Console da AWS:**
1. Acesse o serviço **VPC**.
2. Selecione **Your VPCs** e clique em **Create VPC**.
3. Insira os detalhes acima e crie a VPC.

---

### 2. Configuração das Subnets
#### Subnet Pública:
- **Nome**: vpcwordpress-subnet-public1-us-east-1a
- **Bloco CIDR**: 10.0.1.0/24  
- **Zona de Disponibilidade**: us-east-1a  

#### Subnet Privada:
- **Nome**: vpcwordpress-subnet-private1-us-east-1a
- **Bloco CIDR**: 10.0.2.0/24  
- **Zona de Disponibilidade**: us-east-1a  

**No Console da AWS:**
1. Acesse **Subnets** dentro do serviço **VPC**.
2. Crie as subnets com os detalhes acima.

---

### 3. Configuração do Internet Gateway
- **Nome**: vpcwordpress-igw
- **Associar à VPC**:  vpcwordpress-vpc 

**No Console da AWS:**
1. Acesse **Internet Gateways** no serviço **VPC**.
2. Crie o IGW e associe-o à VPC.

---

### 4. Configuração do NAT Gateway
- **Subnet**: Subnet-Publica  
- **Elastic IP**: Alocar um novo Elastic IP  

**No Console da AWS:**
1. Acesse **NAT Gateways** dentro do serviço **VPC**.
2. Crie o NAT Gateway e configure o Elastic IP.

---

### 5. Configuração das Tabelas de Roteamento
#### Tabela de Roteamento da Subnet Pública:
- **Rota**: 0.0.0.0/0 via Internet Gateway (vpcwordpress-igw)  

#### Tabela de Roteamento da Subnet Privada:
- **Rota**: 0.0.0.0/0 via NAT Gateway (wordpress-gateway-Nat)  

**No Console da AWS:**
1. Acesse **Route Tables** no serviço **VPC**.
2. Atualize as tabelas de roteamento conforme necessário.

---

### 6. Configuração dos Security Groups
#### SG-Privado:
- **Regras de Entrada**:
  - HTTP: Porta 80, origem : wordwpress-LoadBalancer
  - SSH: Porta 22, origem : wordpress-BastionHost  

#### SG-LoadBalancer:
- **Regras de Entrada**:
  - HTTP: Porta 80, origem: 0.0.0.0/0  

#### SG-RDS:
- **Regras de Entrada**:
  - MySQL/Aurora: Porta 3306, origem : SG-Privado  

**No Console da AWS:**
1. Acesse **Security Groups** no serviço **EC2**.
2. Crie os grupos com as regras de entrada e saída descritas.

---

### 7. Lançamento da Instância EC2 Privada
- **AMI**: Ubuntu  24.04 
- **Tipo de Instância**: t2.micro  
- **Subnet**: Subnet-Privada  
- **Security Group**: SG-Privado  

**No Console da AWS:**
1. Acesse o serviço **EC2**.
2. Execute uma instância com as configurações acima.

---

### 8. Configuração do RDS MySQL
- **Engine**: MySQL  
- **Versão**: Compatível com o WordPress  
- **Instância**: db.t2.micro  
- **Credenciais**: Username e senha segura  
- **Subnet Group**: Subnets privadas  
- **Security Group**: SG-RDS  

**No Console da AWS:**
1. Acesse o serviço **RDS**.
2. Crie o banco com os detalhes acima.

---

### 9. Configuração do Load Balancer
- **Nome**:wordpress-LoadBalancer 
- **VPC**: vpcwordpress-vpc  
- **Subnets**: Subnet-Publica  
- **Security Group**: wordwpress-LoadBalancer
- 
**No Console da AWS:**
1. Acesse o serviço **EC2**, em **Load Balancers**.
2. Configure o **Health Check**:  
   - Ping Protocol: HTTP  
   - Ping Port: 80  
   - Ping Path: /healthcheck.html  

3. Adicione a instância EC2 privada.

---

### 10. Implantação do WordPress com Docker
#### Instalar Docker e Docker Compose:
```bash
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### Criar o arquivo `docker-compose.yml`:
```yaml
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: <seu endpoint rds>
      WORDPRESS_DB_USER: <seu usuário>
      WORDPRESS_DB_PASSWORD: <sua senha>
      WORDPRESS_DB_NAME: <nome da database>
    volumes:
      - /efs/wordpress::/var/www/html
```

#### Implementar WordPress:
```bash
mkdir ~/wp && cd ~/wp
sudo vim docker-compose.yml  # Cole o conteúdo acima
docker-compose up -d
```

#### Criar o Arquivo `healthcheck.html`:
```bash
sudo touch healthcheck.html
echo "OK" > /healthcheck.html
```

#### Verificar logs e status:
```bash
docker ps
docker logs <id-do-conteiner>
```

---

### 11. Testes e Validação
#### Verificar o Status do Load Balancer:
- Certifique-se de que a instância está **InService**.

#### Acessar o WordPress via Navegador:
- Acesse: `http://<DNS-do-Load-Balancer>`.

#### Concluir a Instalação do WordPress:
- Siga as instruções na tela para configurar o WordPress.

### Resumo da Instalação do WordPress com Docker e Docker Compose

Após rodar o comando `docker compose up -d`, o WordPress estará em funcionamento. Para concluir a instalação, siga os passos abaixo:

1. **Acessar o WordPress no Navegador**:
   - Acesse o endereço `http://<DNS-do-Load-Balancer` no navegador.

2. **Configuração Inicial**:
   - Escolha o idioma (ex: "Português do Brasil").
   - O WordPress buscará automaticamente as configurações do banco de dados a partir das variáveis no `docker-compose.yaml`.
   - Caso necessário, insira manualmente as informações:
     - **Nome do Banco de Dados**
     - **Usuário**
     - **Senha**
     - **Host**

3. **Configuração do Site**:
   - Preencha as informações do site:
     - **Título do site**
     - **Nome de usuário e senha do administrador**
     - **E-mail do administrador**
     - **Visibilidade do site** (geralmente, público)

4. **Finalizar a Instalação**:
   - Clique em "Instalar WordPress".
   - Após a instalação, você verá a mensagem de sucesso.

5. **Login no WordPress**:
   - Acesse o painel de administração em `http://<seu_ip>/wp-admin`.
   - Use as credenciais do administrador para configurar seu site.

---

**Nota**: O processo de instalação do WordPress é basicamente a configuração do idioma, banco de dados, título do site e credenciais de administrador.





