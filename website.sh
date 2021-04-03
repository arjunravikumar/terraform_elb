#!/bin/bash
yum install httpd -y
echo "You are connected to $(hostname)" > /var/www/html/index.html
service httpd start
chkconfig httpd on