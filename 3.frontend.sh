#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx -y
VALIDATE $? "Disabling nginx Default version"

dnf module enable nginx:1.24 -y
VALIDATE $? "Enabling nginx:1.24"

dnf install nginx -y
VALIDATE $? "Installing nginx:1.24"

systemctl enable nginx 
VALIDATE $? "nginx service enabled"

systemctl start nginx 
VALIDATE $? "nginx service started"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "default nginx content removed"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "frontend content downloaded"

cd /usr/share/nginx/html 
VALIDATE $? "changed directory to html"

unzip /tmp/frontend.zip
VALIDATE $? "unzip content in /usr/share/nginx/html "

mv /etc/nginx/nginx.conf /etc/nginx/backup_nginx.conf
VALIDATE $? "took backup of nginx.conf "

cp $SCRIPT_DIR/nginx.conf /etc/nginx/
VALIDATE $? "nginx.conf copied in /etc/nginx/"

sed -i 's|location /api/catalogue/ { proxy_pass http://localhost:8080/; }|location /api/catalogue/ { proxy_pass http://catalogue.manidevops.online:8080/; }|g' /etc/nginx/nginx.conf
VALIDATE $? "catalogue dns updated in /etc/nginx/nginx.conf"

systemctl restart nginx 
VALIDATE $? "Restarted nginx"