#4. Check score using if else

#! /bin/bash

read -p "Enter the score that you got:" score

if [ $score -ge 90 ]; then
    echo "grade: A"
elif [ $score -ge 80 ]; then
    echo "grade: B"
elif [ $score -ge 70 ]; then
    echo "grade: C"
else
    echo "FAIL"

fi
