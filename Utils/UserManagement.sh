#!/bin/bash

create_user() {
    read -p "Enter the username: " username
    read -p "Enter the password: " password
    useradd "$username" -m -s /bin/bash
    echo "$username:$password" | chpasswd
    echo "User '$username' created with password: $password"
}

delete_user() {
    read -p "Enter the username to delete: " username
    userdel -r "$username"
    echo "User '$username' deleted"
}

modify_user_permissions() {
    read -p "Enter the username: " username
    read -p "Enter the permissions (comma-separated): " permissions
    sermod -aG "$permissions" "$username"
    echo "User '$username' permissions modified: $permissions"
}

reset_password() {
    read -p "Enter the username: " username
    read -p "Enter the new password: " new_password
    echo "$username:$new_password" | chpasswd
    echo "Password reset for user '$username': $new_password"
}

set_ssh_keys() {
    read -p "Enter the username: " username
    read -p "Enter the path to the SSH key file: " ssh_key_path
    echo "Setting SSH keys for user '$username'..."
    mkdir -p "/home/$username/.ssh"
    cat "$ssh_key_path" > "/home/$username/.ssh/authorized_keys"
    chown -R "$username:$username" "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    chown "$username:$username" "/home/$username/.ssh/authorized_keys"
    chmod 600 "/home/$username/.ssh/authorized_keys"
    echo "SSH keys set for user '$username'"
}

# Main menu
while true; do
    clear
    echo "Hydrabank | User Management"
    echo "----------------------"
    echo "1. Create a user"
    echo "2. Delete a user"
    echo "3. Modify user permissions"
    echo "4. Reset user password"
    echo "5. Set SSH keys for a user"
    echo "6. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            create_user
            ;;
        2)
            delete_user
            ;;
        3)
            modify_user_permissions
            ;;
        4)
            reset_password
            ;;
        5)
            set_ssh_keys
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    read -p "Press Enter to continue..."
done
