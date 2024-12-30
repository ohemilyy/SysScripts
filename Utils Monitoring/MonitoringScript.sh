#!/bin/bash

# Discord webhook URL
webhook_url=""

c_pid=$$

send_discord_webhook() {
    local title="$1"
    local message="$2"

    curl -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "content": null,
        "embeds": [
            {
                "title": "'"${title//\"/\\\"}"'",
                "description": "'"${message//\"/\\\"}"'",
                "author": {
                    "name": "PinkCloud | Frontier",
                    "icon_url": "https://i.imgur.com/l3FRPAW.png"
                },
                "footer": {
                    "text": "'"$(hostname)"' (process '$c_pid')",
                    "icon_url": "https://i.imgur.com/l3FRPAW.png"
                },
                "timestamp": "'$(date +"%Y-%m-%dT%H:%M:%S%z")'"
            }
        ]
    }' \
    "$webhook_url"
}

check_cpu_utilization() {
    local threshold=220  

    local cpu_utilization=$(top -bn1 | awk 'NR>7{s+=$9}END{print s}')
    echo "CPU Utilization: $cpu_utilization%"

    if (( $(echo "$cpu_utilization > $threshold" | bc -l) )); then
        send_discord_webhook "Influx in CPU load detected" "An influx of CPU utilization was detected (above $threshold%): $cpu_utilization%"
        echo "High CPU utilization detected: $cpu_utilization%"
    fi
}

check_ram_usage() {
    local threshold=90  

    local ram_usage=$(free | awk '/Mem/{printf("%.2f"), $3/$2 * 100}')
    local ram_usage_int=${ram_usage%.*}  # Extract the integer part
    echo "RAM Usage: $ram_usage%"

    if [[ $ram_usage_int -gt $threshold ]]; then
        send_discord_webhook "High RAM usage detected" "HIGH RAM USAGE DETECTED: $ram_usage%"
        echo "High RAM usage detected: $ram_usage%"
    fi
}

check_drive_health_usage() {
    local threshold=90  

    if command -v smartctl &>/dev/null; then
        local drives=("/dev/md1") 

        for drive in "${drives[@]}"; do
            local usage=$(df -h "$drive" | awk 'NR==2{print $5}' | sed 's/%//')
            echo "Drive: $drive, Usage: $usage%, Health: $health"

            if [[ $usage -gt $threshold ]]; then
                send_discord_webhook "High drive usage (capacity) detected" "HIGH USAGE DETECTED: $drive - $usage%"
                echo "High drive usage detected: $drive - $usage%"
            fi
        done
    fi
}

check_network_traffic() {
    local threshold=50  

    if command -v vnstat &>/dev/null; then
        local interface="enp38s0" 

        local trafficOutput=$(vnstat -i "$interface" -tr 5)
        local traffic=$(echo "$trafficOutput" | awk '/rx/ {print $2}')
        local trafficUnit=$(echo "$trafficOutput" | awk '/rx/ {print $3}')
        echo "Network Traffic: $traffic $trafficUnit"
        if [[ $(echo "$traffic > $threshold" | bc -l) -eq 1 ]]; then
            if [[ $trafficUnit == "Mbit/s" ]]; then
                send_discord_webhook "High network traffic detected" "HIGH NETWORK TRAFFIC DETECTED: $traffic $trafficUnit"
                echo "High network traffic detected: $traffic $trafficUnit"
            fi
        fi
    else
        echo "vnstat not installed, attempting to install it..."
        # install vnstat if on debian/ubuntu
        if command -v apt &>/dev/null; then
            sudo apt install vnstat -y
            check_network_traffic
        # install vnstat if on EL
        elif command -v yum &>/dev/null; then
            sudo yum install vnstat -y
            check_network_traffic
        else
            send_discord_webhook "ALERT: vnstat not installed" "\`vnstat\` is not installed. Please install it in order to monitor network traffic."
            echo "vnstat not installed, please install it in order to monitor network traffic."
        fi
    fi
}


function mainMonitoringThread() {
    while true; do
        check_cpu_utilization
        check_ram_usage
        check_drive_health_usage
        check_network_traffic

        sleep 60  
    done
}

function insightsMonitoringThread() {
    while true; do
        local trafficOutput=$(vnstat -i "enp38s0" -tr 5)
        # remove /s from the output
        local trafficUnit=$(echo "$trafficOutput" | awk '/rx/ {print $3}' | sed 's/\/s//')
        local traffic=$(echo "$trafficOutput" | awk '/rx/ {print $2}')
        local cpu_utilization=$(top -bn1 | awk 'NR>7{s+=$9}END{print s}')
        local ram_usage=$(free | awk '/Mem/{printf("%.2f"), $3/$2 * 100}')
        local drive_usage=$(df -h | awk 'NR==2{print $5}' | sed 's/%//')
        local json=$(echo '{
            "content": null,
            "embeds": [
                {
                    "title": "Routine Server Insights",
                    "description": "This is a routine server insights report.",
                    "fields": [
                        {
                            "name": "CPU Utilization",
                            "value": "'\`$cpu_utilization%\`'",
                            "inline": true
                        },
                        {
                            "name": "RAM Usage",
                            "value": "'\`$ram_usage%\`'",
                            "inline": true
                        },
                        {
                            "name": "Drive Usage",
                            "value": "'\`$drive_usage%\`'",
                            "inline": true
                        },
                        {
                            "name": "Network Traffic",
                            "value": "'\`${traffic//\"/\\\"}\` ${trafficUnit//\"/\\\"}'",
                            "inline": true
                        }
                    ],
                    "author": {
                        "name": "PinkCloud | Frontier",
                        "icon_url": "https://i.imgur.com/l3FRPAW.png"
                    },
                    "footer": {
                        "text": "'"$(hostname)"' (process '$c_pid')",
                        "icon_url": "https://i.imgur.com/l3FRPAW.png"
                    },
                    "timestamp": "'$(date +"%Y-%m-%dT%H:%M:%S%z")'"
                }
            ]
        }')

        # normalise the json and send it, no jq
        curl -X POST \
        -H "Content-Type: application/json" \
        -d "$json" \
        "$webhook_url"

        # sleep for (NOT 30 MINUTES ANYMORE) 2 hours
        sleep 7200
    done
}

mainMonitoringThread &
mmt_pid=$!

insightsMonitoringThread &
imt_pid=$!

send_discord_webhook "New monitoring process started" "**Main monitoring thread** PID: \`$mmt_pid\`\n**Insights monitoring thread** PID: \`$imt_pid\`"

trap 'send_discord_webhook "Monitoring process stopped" "**Main monitoring thread** PID: \`$mmt_pid\`\n**Insights monitoring thread** PID: \`$imt_pid\`"' EXIT
wait $mmt_pid $imt_pid
