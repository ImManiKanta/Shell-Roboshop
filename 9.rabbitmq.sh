#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Copying rabitmq.repo to /etc/yum.repos.d "



dnf list installed rabbitmq-server
    if [ $? -ne 0 ]; then 
       dnf install rabbitmq-server -y &>>$LOGS_FILE
       VALIDATE $? "Installing rabbitmq-server"
    else
        echo "rabbitmq-server already installed $Y skipping $N"
    fi

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "rabbitmq-server service enabled and started"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi



