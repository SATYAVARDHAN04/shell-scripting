#3. Password length check (#)

#! /bin/bash

read -p "Enter the password: " password

if [ ${#password} -gt 8 ]; then
    echo "Password is strong"

else
    echo "Password is not strong"

fi
