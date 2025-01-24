#!/usr/bin/env bash

if [ ! "$EUID" -eq 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

clear
echo "Welcome to the LunarShell installer. This script will install LunarShell on your system, which includes custom utilities and a custom prompt, along with custom MOTDs."
read -p "Do you want to continue with installing LunarShell? [y/N] " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo "Fetching relevant files for your Linux distribution..."

check_distroreqs() {
    KERNELVER=`uname -r`
    if [ -f "/etc/arch-release" ]; then
        DIST=arch
    elif [ -f "/etc/debian_version" ]; then
        DIST=debian
        UBUNTU_VERSION=$(lsb_release -rs)
    elif [ -f "/etc/redhat-release" ]; then
        DIST=el
        EL_MAJOR_VERSION=`sed -rn 's/.*([0-9])\.[0-9].*/\1/p' /etc/redhat-release`
        if [ -f "/etc/fedora-release" ]; then
            DIST=fedora
        fi
    fi
}

check_distroreqs

if [[ "$DIST" == "debian" ]]; then
    if echo $UBUNTU_VERSION | grep "..\..." > /dev/null; then
        echo "Ubuntu or its derivative detected, downloading LunarShell for Ubuntu.."
        curl -fsSL https://shell.lunarlabs.cc/src/distros/ubuntu.sh | bash -E -
    else
        echo "Debian and its derivatives are not supported."
    fi
elif [[ "$DIST" == "el" ]]; then
    echo "Detected Enterprise Linux, detecting version of EL.."
    if [[ "$EL_MAJOR_VERSION" -eq 8 ]]; then
        echo "EL8 detected, downloading LunarShell for Enterprise Linux 8.."
        curl -fsSL https://shell.lunarlabs.cc/src/distros/el8.sh | bash -E -
    elif [[ "$EL_MAJOR_VERSION" -eq 7 ]]; then
        echo "EL7 detected, downloading LunarShell for Enterprise Linux 7.."
        echo "Enterprise Linux 7 is not supported."
    elif [[ "$EL_MAJOR_VERSION" -eq 9 ]]; then
        echo "EL9 detected, downloading LunarShell for Enterprise Linux 8 (compatible with EL9).."
        curl -fsSL https://shell.lunarlabs.cc/src/distros/el8.sh | bash -E -
    else
        echo "Your version of Enterprise Linux is not supported."
    fi
elif [[ "$DIST" == "arch" ]]; then
    echo "Arch Linux detected, detecting Arch kernel version.."
    echo "Arch Linux version is $KERNELVER"
    echo "Downloading LunarShell.sh for Arch.."
    sleep 5
    echo "lol jk there's no arch version lmao"
fi
