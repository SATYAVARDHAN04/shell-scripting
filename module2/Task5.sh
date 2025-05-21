# Temperature Conversion and Validation
# Write a shell script that:

# Prompts the user to enter a temperature in Celsius (e.g., 25).
# Converts the temperature to Fahrenheit using the formula: F = (C * 9/5) + 32.
# Compares the Fahrenheit temperature to thresholds: freezing (≤32°F), comfortable (60–80°F), or hot (>80°F).
# Displays the converted temperature and its category (e.g., “25°C is 77°F, comfortable”).
# Validates that the input is a numeric value using a string comparison or regex.
# Uses arithmetic operations for conversion and conditional statements for categorization.

read -p "Enter the temperature in c:" cel
far=$(((cel * 9 / 5) + 32))

if [ "$far" -le 32 ]; then
    note="freezing"
elif [ "$far" -ge 60 ] && [ "$far" -le 80 ]; then
    note="comfortable"
else
    note="Hot"

fi

echo "$cel°C is $far°F, $note"
