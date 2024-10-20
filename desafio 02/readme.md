# Modificação e Melhoria do Código Terraform

## Foram feitas as seguintes alterações

Primeiramente adicão do "header" onde é especificado a versão de uso e providers requeridos, isso garante uma maior segurança e deixa mais claro para outros desenvolvedores que trabalham com codigo, saber qual versão e oq esta ou nao depreciado pelo terraform.

```terraform
terraform {
  required_version = "1.9.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.72.1"
    }
  }
}
```

Adição do meu nome a variavel candidato.

```terraform
variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "Artur"
}
```

No recurso `aws_route_table_association` foi removido o campo tags, pois não é aceito e gerava erro no codigo.

Aqui houve as mudanças mais significativas, tanto para resolver bugs como para fazer a instalação e funcionamento correto do nginx.

Mudança na `description`, removido acentos, pois geram erro ao executar o terraform apply.

Adição de uma nova regra de entrada, na porta 80, para permitir o browser se conectar com a instancia.
Remoção de todos endereços ipv6, para poder restringir o acesso.

```terraform
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o trafego de saida"
  vpc_id      = aws_vpc.main_vpc.id


  # Regras de entrada
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
```

Dentro de `aws_instance` tambem houveram mudanças.

Primeiramente na mudança de `security_groups = [aws_security_group.main_sg.name]` para `vpc_security_group_ids = [aws_security_group.main_sg.id]` pois como a variavel diz, precisa ser os ids do grupo de segurança e não o nome.

Mudança no `user_data` para aceitar o script [user_data.sh](https://github.com/focarica/VExpenses/blob/main/desafio%2002/user_data.sh), onde é feita a instalação e iniciação basica do servidor nginx.
