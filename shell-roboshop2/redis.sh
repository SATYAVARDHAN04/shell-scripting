#!/bin/bash

# Colors
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Variables
USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

# Create log folder
mkdir -p $LOG_FOLDER
echo "Script started at: $(date)" | tee -a $LOG_FILE

# Root access check
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root privileges $N" | tee -a $LOG_FILE
    exit 1
fi

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable redis -y &>>$LOG_FILE
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Disabling and enabling Redis module"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/redis.conf
VALIDATE $? "Updated bind address to allow remote access"

sed -i 's/protected-mode yes/protected-mode no/' /etc/redis.conf
VALIDATE $? "Disabled protected mode to allow external connections"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling Redis service"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting Redis service"
