#!/bin/bash

# Discord webhook URL
webhook_url="https://discord.com/api/webhooks/your_webhook_url"

send_discord_webhook() {
    local message="$1"

    curl -X POST -H "Content-Type: application/json" -d '{
        "content": "",
        "embeds": [
            {
                "title": "Software Update",
                "description": "'"${message//\"/\\\"}"'",
                "color": 16776960
            }
        ]
    }' "$webhook_url"
}

echo "Checking for available updates..."
apt_update_output=$(apt update 2>&1)
available_updates=$(apt list --upgradable 2>/dev/null | grep -v Listing | wc -l)

if [ "$available_updates" -gt 0 ]; then
    echo "Found $available_updates available update(s)."
    send_discord_webhook "Found $available_updates available update(s)."
else
    echo "No updates available."
    send_discord_webhook "No updates available."
    exit 0
fi

echo "Performing system update..."
apt_upgrade_output=$(apt upgrade -y 2>&1)

if [ $? -eq 0 ]; then
    echo "System update completed successfully."
    send_discord_webhook "System update completed successfully."
else
    echo "An error occurred during the system update."
    send_discord_webhook "An error occurred during the system update."
fi
