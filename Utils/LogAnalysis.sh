#!/bin/bash

generate_report() {
    local log_file="$1"
    local pattern="$2"

    echo "Generating report for pattern: $pattern"

    grep "$pattern" "$log_file" > report.txt

    cat report.txt
}

send_alert() {
    local log_file="$1"
    local pattern="$2"
    local recipient="$3"

    echo "Sending alert for pattern: $pattern"

    grep "$pattern" "$log_file" > alert.txt

    echo "Alert: $(cat alert.txt)" | mail -s "Log Analysis Alert" "$recipient"

    rm alert.txt
}

# Main menu
while true; do
    clear
    echo "Hydrabank | Log Analysis"
    echo "------------------"
    echo "1. Generate a report"
    echo "2. Send an alert"
    echo "3. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter the path to the log file: " log_file
            read -p "Enter the pattern to search for: " pattern
            generate_report "$log_file" "$pattern"
            ;;
        2)
            read -p "Enter the path to the log file: " log_file
            read -p "Enter the pattern to search for: " pattern
            read -p "Enter the recipient's email address: " recipient
            send_alert "$log_file" "$pattern" "$recipient"
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    read -p "Press Enter to continue..."
done
