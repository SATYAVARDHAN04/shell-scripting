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

# Create log folder
mkdir -p $LOG_FOLDER
echo "Script started at: $(date)" | tee -a $LOG_FILE

# Root access check
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root privileges $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access." | tee -a $LOG_FILE
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

# Step 1: Copy repo
cp mongo.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB repo"

# Step 2: Install MongoDB
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

# Step 3: Enable service
systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB service"

# Step 4: Start service
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB service"

# Step 5: Update bind IP to allow external connections
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
VALIDATE $? "Editing mongod.conf for remote connections"

# Step 6: Restart service
systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"
