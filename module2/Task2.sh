# 2. Compare two numbers

read -p "Enter 2 numbers to comapre" a b

if [ $a -gt $b ]; then
    echo -n "The number $a is greater than $b"
else
    echo -n "The number $b is greater than $a"

fi
