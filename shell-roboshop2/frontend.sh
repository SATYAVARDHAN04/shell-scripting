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

dnf module list nginx &>>$LOG_FILE

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling default Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx 1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Enabling and Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Remove the default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Download the frontend content"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extract the frontend content"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx Server"
