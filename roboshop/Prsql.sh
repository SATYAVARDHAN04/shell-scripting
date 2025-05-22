#! /bin/bash

UserID=$(id -u)
if [ $UserID -eq 0]; then
    echo "Installing MySQL"
else
    echo "You should be a root user to install MySQL"
    exit 1
fi

dnf install mysql-community-server -y
if [$? -ne 0]; then
    echo "Sorry inatllation failed"
    exit 1
else
    echo "Installation success"
fi
