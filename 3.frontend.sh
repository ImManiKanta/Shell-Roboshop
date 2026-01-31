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

dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "Disabling nginx Default version"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nginx:1.24"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing nginx:1.24"

systemctl enable nginx &>>$LOGS_FILE
VALIDATE $? "nginx service enabled"

systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "nginx service started"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "default nginx content removed"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "frontend content downloaded"

cd /usr/share/nginx/html &>>$LOGS_FILE
VALIDATE $? "changed directory to html"

unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "unzip content in /usr/share/nginx/html "

mv /etc/nginx/nginx.conf /etc/nginx/backup_nginx.conf &>>$LOGS_FILE
VALIDATE $? "took backup of nginx.conf "

cp $SCRIPT_DIR/nginx.conf /etc/nginx/ &>>$LOGS_FILE
VALIDATE $? "nginx.conf copied in /etc/nginx/"

sed -i 's|location /api/catalogue/ { proxy_pass http://localhost:8080/; }|location /api/catalogue/ { proxy_pass http://catalogue.manidevops.online:8080/; }|g' /etc/nginx/nginx.conf
VALIDATE $? "catalogue dns updated in /etc/nginx/nginx.conf"

sed -i 's|location /api/cart/ { proxy_pass http://localhost:8080/; }|location /api/catalogue/ { proxy_pass http://cart.manidevops.online:8080/; }|g' /etc/nginx/nginx.conf
VALIDATE $? "cart dns updated in /etc/nginx/nginx.conf"

sed -i 's|location /api/user/ { proxy_pass http://localhost:8080/; }|location /api/catalogue/ { proxy_pass http://user.manidevops.online:8080/; }|g' /etc/nginx/nginx.conf
VALIDATE $? "user dns updated in /etc/nginx/nginx.conf"

systemctl restart nginx &>>$LOGS_FILE
VALIDATE $? "Restarted nginx"