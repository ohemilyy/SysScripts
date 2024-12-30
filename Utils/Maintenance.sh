#!/bin/bash

# Function to clean up temporary files
cleanup_temp_files() {
    echo "Cleaning up temporary files..."

    rm -rf /tmp/*
    rm -rf /var/tmp/*
    find /var/log -type f -name '*.log' -exec rm {} \;

    echo "Temporary files cleaned up."
}

optimize_databases() {
    echo "Optimizing databases..."

    # TODO: do this 
    echo "Databases optimized."
}

# Function to restart services
restart_services() {
    echo "Restarting services..."

    systemctl restart nginx
    systemctl restart sshd
    systemctl restart mongod
    systemctl restart redis

    echo "Services restarted."
}

manage_system_updates() {
    echo "Managing system updates..."

    apt update && apt upgrade -y

    echo "System updates managed."
}

while true; do
    clear
    echo "Hydrabank | System Maintenance"
    echo "------------------------"
    echo "1. Clean up temporary files"
    echo "2. Optimize databases"
    echo "3. Restart services"
    echo "4. Manage system updates"
    echo "5. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            cleanup_temp_files
            ;;
        2)
            optimize_databases
            ;;
        3)
            restart_services
            ;;
        4)
            manage_system_updates
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    read -p "Press Enter to continue..."
done
