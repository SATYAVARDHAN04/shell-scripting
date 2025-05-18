#!/bin/bash

USERNAME=$(id -u)

if [ "$USERNAME" -eq 0 ]; then
    echo "Sorry, cannot perform"
else
    echo "Can perform"
fi
