#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p "$LOGS_FOLDER"
echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

# Root check
if [ "$USERID" -ne 0 ]; then
    echo -e "$R ERROR: Run the script as root $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo -e "$G Running with root access $N" | tee -a "$LOG_FILE"
fi

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# NodeJS setup
dnf module disable nodejs -y &>>"$LOG_FILE"
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>"$LOG_FILE"
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>"$LOG_FILE"
VALIDATE $? "Installing nodejs"

# roboshop user setup
id roboshop &>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOG_FILE"
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "User 'roboshop' already exists ... $Y SKIPPING $N" | tee -a "$LOG_FILE"
fi

# App setup
mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>"$LOG_FILE"
VALIDATE $? "Downloading catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>"$LOG_FILE"
VALIDATE $? "Unzipping catalogue"

npm install &>>"$LOG_FILE"
VALIDATE $? "Installing Node.js dependencies"

cp "$SCRIPT_DIR/catalogue.service" /etc/systemd/system/catalogue.service &>>"$LOG_FILE"
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>"$LOG_FILE"
systemctl enable catalogue &>>"$LOG_FILE"
systemctl start catalogue &>>"$LOG_FILE"
VALIDATE $? "Starting catalogue service"

# MongoDB client and data setup
cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo &>>"$LOG_FILE"
dnf install mongodb-mongosh -y &>>"$LOG_FILE"
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
