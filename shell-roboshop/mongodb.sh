#!/bin/bash

USERID=$(id -u)
R="\033[31m"
G="\033[32m"
Y="\033[33m"
N="\033[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"
echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

# Check root privileges
if [ "$USERID" -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo "You are running with root access" | tee -a "$LOG_FILE"
fi

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}

cp mongo.repo /etc/yum.repos.d/mongodb.repo &>>"$LOG_FILE"
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>"$LOG_FILE"
VALIDATE $? "Installing MongoDB server"

systemctl enable mongod &>>"$LOG_FILE"
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>"$LOG_FILE"
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>"$LOG_FILE"
VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>"$LOG_FILE"
VALIDATE $? "Restarting MongoDB"

echo "Script completed at: $(date)" | tee -a "$LOG_FILE"
