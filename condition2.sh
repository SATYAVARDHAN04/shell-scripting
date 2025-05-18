#!/bin/bash

USERNAME=$(id -u)

if [ "$USERNAME" -neq 0 ]; then
    echo "Sorry, cannot perform"
else
    echo "Can perform"
fi
