#!/bin/bash

# Start time
START_TIME=$(date +%s)

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Variables
USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

# Create log folder
mkdir -p $LOG_FOLDER
echo "Script started at: $(date)" | tee -a $LOG_FILE

# Root check
if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root privileges $N" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G Running with root privileges $N" | tee -a $LOG_FILE
fi

# Prompt for password securely
echo -n "Enter MySQL root password: "
read -s MYSQL_ROOT_PASSWORD
echo

# Validate function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

# MySQL installation
dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MySQL"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting MySQL"

mysql_secure_installation --set-root-pass "$MYSQL_ROOT_PASSWORD" &>>$LOG_FILE
VALIDATE $? "Setting MySQL root password"

# End time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "$Y Script completed in $DURATION seconds $N" | tee -a $LOG_FILE
