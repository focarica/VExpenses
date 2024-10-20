# Resolução Desafio Vexpenses

Arquivos do desafio de [Analise Tecnica](https://github.com/focarica/VExpenses/tree/main/desafio%2001)

Arquivos do desafio de [Modificação e Melhoria](https://github.com/focarica/VExpenses/tree/main/desafio%2002)

## Como executar o arquivo modificado.

- Efetue a criação de uma conta na AWS
- Instale o Terraform CLI no seu computador
- Realizes os comandos
  ```bash
  git clone https://github.com/focarica/VExpenses.git
  cd VExpenses/desafio02
  ```
- Execute `terraform init` para iniciar a infraestrutura.
- Execute `terraform apply` para aplicar o arquivo terraform a Aws.
- Ao terminar sera gerado um output com o IP. Copie e cole no seu navegador. Pode demorar alguns segundos ate que a pagina carregue pois a instancia acabou de ser criada.
- Quando desejar parar a instancia execute `terraform destroy` para destruir a infraestrutura criada
