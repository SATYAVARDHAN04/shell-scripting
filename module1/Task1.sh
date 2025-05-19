# Task 1: Create a basic script to display system information
# Display the current user.
# Display the current directory.
# Display today's date in the format: Day, Month Date, Year (e.g., Tuesday, October 10, 2023).
# Display the system uptime.

#! /bin/bash

echo "The current user is $(whoami)"
echo "The current directory is $(pwd)"
echo "Today's date is $(date '+%A, %B %d, %Y')"
echo "The system uptime is $(uptime -p)"
