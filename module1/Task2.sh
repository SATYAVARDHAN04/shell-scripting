# Task 2: Write an interactive script
# Write a shell script that:
# 	Asks the user for their name.
# 	Asks the user for their favorite place.
# 	Displays a message like: "Hello [Name], your favorite place is [Place]!"

#! /bin/bash

echo "Hello, what is your name?"
read name

echo "What is your favorite place"
read place

echo "Hello $name, your favorite place is $place!"
