#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.manidevops.online

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

dnf install maven -y
VALIDATE $? "Installing maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading shipping code"

cd /app 
VALIDATE $? "change dir 'cd' "

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip
VALIDATE $? "unzip the shipping code"

mvn clean package 
VALIDATE $? "clean and build the files"

mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copy shipping.service to /etc/systemd/system/"

systemctl daemon-reload

systemctl enable shipping 

systemctl start shipping
VALIDATE $? "Shipping service enabled and started"

dnf install mysql -y 
VALIDATE $? "Installing Mysql client"

mysql -h mysql.manidevops.online -uroot -pRoboShop@1 < /app/db/schema.sql

mysql -h mysql.manidevops.online -uroot -pRoboShop@1 < /app/db/app-user.sql 

mysql -h mysql.manidevops.online -uroot -pRoboShop@1 < /app/db/master-data.sql

systemctl restart shipping
VALIDATE $? "Shipping service restarted"

echo "port check ----------------"
nestat -lntp
echo "----------------"