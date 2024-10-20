# VExpenses

Repositorio para solução das tarefas do processo seletivo.

## Análise Técnica do Código Terraform

O programa é iniciado declarando o provider da aws na região "us-east-1", apesar de ter uma mais perto em são paulo, ela é um pouco mais cara e possui menos recursos que a utilizada. Essa parte é basicamente dizer para o terraform qual serviço de cloud sera usado, poderia ser Azure, Google Cloud e etc

```terraform
provider "aws" {
  region = "us-east-1"
}
```

Seguindo, temos a declaração de duas variaveis, guardando o nome do projeto e do candidato, nada diferente do que ocorre em linguagens de programação comuns.

```terraform
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}
```

Aqui é criado um par de chaves compativel com SSH utilizando criptografia rsa com tamanho de 2048 bits. Em sequencia, o recurso `aws_key_pair` é criado para controlar o login nas instancias. Por exemplo, para acessar o terminal da instancia EC2 criada remotamente.

```terraform
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" { 
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}
```

É iniciado as configurações gerais de rede, iniciando com a criação de uma nuvem privada virtual, ou vpc. Aqui passado um `cidr_block` com valor padrão e habilitando algumas configurações de dns.

```terraform
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}
```

Criação de uma subrede com o vpc criado no bloco acima.

```terraform
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}
```

Criação de um gateway.

```terraform
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}
```

Aqui é criado uma tabela de rotas, onde determinamos onde nossa rede ou gateway sera direcionado, serve como auxiliar para o recurso criado abaixo.

```terraform
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}
```

Faz a associação das subredes com a tabela de rotas criada anteriormente. Nessa parte é possivel ver um erro na criação das variavel `tags`, pois o recurso nao aceita/nao precisa.

```terraform
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}
```

Nessa parte, a criação de um grupo de segurança é feito, que nada mais é que configurar as regras de acesso e saida da nossa instancia. Nesse caso permitimos o acesso SSH, pela porta 22, a partir de qualquer IP; e permitimos o trafego de saida, tambem a partir de qualquer ip.

```terraform
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}
```

Diferente dos outros blocos de codigo aqui não é criado um recurso e sim um do tipo data, onde basicamente é buscado por uma `ami` com os filtros especificados. Nesse caso com o nome `debian-12-amd64-*`e com virtualização do tipo `hvm`.

```terraform
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}
```

Recurso principal.

```terraform
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}
```

Aqui podemos dizer que é onde o recurso "principal" esta sendo criado. Uma instancia da aws é criada e passado todos os dados que criamos acima para o funcionamento dessa instancia.

1. **`ami`**: Especifica a AMI que foi escolhida para a máquina, permitindo que a AWS saiba qual imagem utilizar. Associamos essa variavel ao resultado da busca feita no bloco acima.

2. **`instance_type`**: Define o tipo de máquina que será usada. Existem diversos valores que representam o poder de processamento da instância. Neste caso, foi utilizado `t2.micro`.

3. **`subnet_id`**: Especifica a sub-rede que será utilizada. Neste caso, ela foi definida em outro bloco.

4. **`key_name`**: Define quais serão as chaves SSH utilizadas para o acesso à instância.

5. **`security_groups`**: Recebe os grupos de segurança que foram criados acima.

6. **`associate_public_ip_address`**: Define se a instância deve receber um endereço IP público.

7. **`root_block_device`**: Especifica o armazenamento utilizado. Neste caso, são 20 GB do tipo `gp2`.

8. **`user_data`**: Funciona como um script que será executado assim que o arquivo Terraform for aplicado. Acredito que uma melhor pratica seria escrever esse arquivo em um arquivo .sh e depois fazer algo como `user_data = file("user_data.sh")`.  

E por ultimo, é criado dois outputs, um para vermos a chave privada e outra para vermos o enderço ip publico. esses valores serão mostrados ao executar o arquivo do terraform, ou ao executar `terraform output`

```terraform
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
```