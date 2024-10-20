#!/bin/bash

sudo su
apt-get update -y
apt-get install -y nginx

systemctl start nginx
systemctl enable nginx

# Html simples apenas para mostrar funcionamento.
echo "<h1>Ola VExpenses!</h1>" > /var/www/html/index.nginx-debian.html
systemctl restart nginx
