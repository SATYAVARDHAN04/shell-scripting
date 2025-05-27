#!/bin/bash

START_TIME=$(date +%s)

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

mkdir -p $LOG_FOLDER
echo "Script started at: $(date)" | tee -a $LOG_FILE

# Root access check
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root privileges $N" | tee -a $LOG_FILE
    exit 1
else
    echo "Running with root access" | tee -a $LOG_FILE
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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default Node.js"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Node.js 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Node.js"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart app"

rm -rf /app/*
cd /app
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Extracting app code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Node.js dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart systemd service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script execution completed successfully, $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
