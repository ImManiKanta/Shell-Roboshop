#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Copying rabitmq.repo to /etc/yum.repos.d "



dnf list installed rabbitmq-server &>>$LOGS_FILE
    if [ $? -ne 0 ]; then 
       echo "Installing rabbitmq-server"
       dnf install rabbitmq-server -y &>>$LOGS_FILE
       VALIDATE $? "rabbitmq-server installation"
    else
        echo -e "rabbitmq-server already installed $Y skipping $N"
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



