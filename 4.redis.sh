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

dnf module disable redis -y
VALIDATE $? "Disabling redis module" 

dnf module enable redis:7 -y
VALIDATE $? "Enabling redis: 7 version" 

dnf install redis -y 
VALIDATE $? "Installing redis" 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections" 


sed -i 's|protected-mode yes|protected-mode no|g' /etc/redis/redis.conf
VALIDATE $? "Protected mode from yes to no" 

systemctl enable redis 
VALIDATE $? "Redis service enabling" 

systemctl start redis 
VALIDATE $? "Redis service started" 