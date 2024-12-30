#!/bin/bash

# Function to send a Discord webhook message
send_discord_webhook() {
    local message="$1"
    local webhook_url=""

    curl -X POST -H "Content-Type: application/json" -d '{
        "content": "",
        "embeds": [
            {
                "title": "Network Configuration",
                "description": "'"${message//\"/\\\"}"'",
                "color": 16711680
            }
        ]
    }' "$webhook_url"
}

setup_firewall() {
    echo "Setting up iptables firewall rules..."
    /sbin/iptables -N PREROUTING
    /sbin/iptables -N WHITELIST
    /sbin/iptables -N SYN_FLOOD
    /sbin/iptables -N port-scanning
    /sbin/iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
    /sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    /sbin/iptables -t mangle -A PREROUTING -f -j DROP
    /sbin/iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    /sbin/iptables -A port-scanning -j DROP
    /sbin/iptables -A PREROUTING -p icmp -j DROP
    /sbin/iptables -A PREROUTING -f -j DROP
    /sbin/iptables -A PREROUTING -p tcp -j WHITELIST
    /sbin/iptables -A WHITELIST -i lo -j RETURN
    /sbin/iptables -A WHITELIST -p tcp -m tcp --dport 22 -j RETURN
    /sbin/iptables -A WHITELIST -p tcp -m tcp --dport 80 -j RETURN
    /sbin/iptables -A WHITELIST -p tcp -m tcp --dport 443 -j RETURN
    /sbin/iptables -A WHITELIST -p tcp -m tcp --dport 25565 -j RETURN
    /sbin/iptables -A WHITELIST -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN
    /sbin/iptables -A WHITELIST -j DROP
    /sbin/iptables -A PREROUTING -p tcp --syn -j SYN_FLOOD
    /sbin/iptables -A SYN_FLOOD -m limit --limit 10000/s --limit-burst 10000 -j RETURN
    /sbin/iptables -A SYN_FLOOD -j DROP
    /sbin/iptables -A PREROUTING -m conntrack --ctstate INVALID -j DROP
    /sbin/iptables -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
    /sbin/iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset
    echo "Iptables firewall rules set up."
}

allow_port() {
    read -p "Enter the port number: " port
    read -p "Enter the protocol (tcp/udp): " protocol

    echo "Allowing access to port $port/$protocol..."

    /sbin/iptables -A WHITELIST -p "$protocol" --dport "$port" -j RETURN

    echo "Access to port $port/$protocol allowed."
}

remove_port_access() {
    read -p "Enter the port number: " port
    read -p "Enter the protocol (tcp/udp): " protocol

    echo "Removing access to port $port/$protocol..."

    /sbin/iptables -D WHITELIST -p "$protocol" --dport "$port" -j RETURN

    echo "Access to port $port/$protocol removed."
}
drop_bogan() {
    echo Are you sure you want to drop bogon networks?
    read -p "Are you sure you want to drop bogon networks? (y/n): " drop_bogon
    echo In most cases, this should be a NO. This will break containerisation software and overlay networking, including Docker and Tailscale/ZeroTier.

    if [[ $drop_bogon =~ ^[Yy]$ ]]; then

    echo "Dropping Bogan Networks"

    echo "Dropping 224.0.0.0/3..."
    /sbin/iptables -A PREROUTING -s 224.0.0.0/3 -j DROP
    echo "Dropping 169.254.0.0/16..."
    /sbin/iptables -A PREROUTING -s 169.254.0.0/16 -j DROP
    echo "Dropping 172.16.0.0/12..."
    /sbin/iptables -A PREROUTING -s 172.16.0.0/12 -j DROP
    echo "Dropping 192.0.2.0/24..."
    /sbin/iptables -A PREROUTING -s 192.0.2.0/24 -j DROP
    echo "Dropping 192.168.0.0/16"
    /sbin/iptables -A PREROUTING -s 192.168.0.0/16 -j DROP
    echo "Dropping 10.0.0.0/8..."
    /sbin/iptables -A PREROUTING -s 10.0.0.0/8 -j DROP
    echo "Dropping 0.0.0.0/8..."
    /sbin/iptables -A PREROUTING -s 0.0.0.0/8 -j DROP
    echo "Dropping 240.0.0.0/5..."
    /sbin/iptables -A PREROUTING -s 240.0.0.0/5 -j DROP
    echo "Dropping 127.0.0.0/8..."
    /sbin/iptables -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP

    echo "Dropped all bogon networks"

    else
        echo "Not dropping bogon networks"
    fi
}

while true; do
    clear
    echo "Firewall Configuration"
    echo "WARNING: DO NOT MESS WITH THIS STUFF UNLESS YOU KNOW WHAT YOU ARE DOING"
    echo "---------------------"
    echo "1. Setup iptables firewall (Only Run Once)"
    echo "2. Allow access to a port"
    echo "3. Remove access to a port"
    echo "4. Drop Bogon Networks"
    echo "5. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            setup_firewall
            ;;
        2)
            allow_port
            ;;
        3)
            remove_port_access
            ;;
        4)
            drop_bogan
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
