#! /bin/bash

USER=$(id -u)
if [ $USER -ne 0 ]; then
    echo "Error: Please run the script with sudo or root user"
    exit 1
else
    echo "Installing MySQL"
fi

apt install mysql-server -y

if [ $? -ne 0 ]; then
    echo "Error: Failed to install MySQL"
    exit 1
else
    echo "MySQL installed successfully"
fi
