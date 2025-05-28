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
if [ "$USERID" -ne 0 ]; then
    echo -e "$R ERROR: Run the script as root $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "$G Running with root access $N" | tee -a "$LOG_FILE"
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

# Create roboshop user if not exists
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

# App setup
mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue app"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Extracting app code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing node dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>"$LOG_FILE"
VALIDATE $? "Copying catalogue systemd service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting catalogue service"

# MongoDB Client & Data Load
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB client"

# Fixed MongoDB data check
STATUS=$(mongosh --quiet --host mongodb.satyology.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")' | grep -Eo '^[0-9]+')
echo "MongoDB STATUS result: $STATUS" | tee -a "$LOG_FILE"

if [[ -z "$STATUS" || "$STATUS" -lt 0 ]]; then
    mongosh --host mongodb.satyology.site </app/db/master-data.js &>>"$LOG_FILE"
    VALIDATE $? "Importing MongoDB data"
else
    echo -e "MongoDB data already exists ... $Y SKIPPING $N" | tee -a "$LOG_FILE"
fi

echo "Script completed at: $(date)" | tee -a "$LOG_FILE"
