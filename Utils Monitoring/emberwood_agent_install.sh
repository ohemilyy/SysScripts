#!/bin/bash
#
#
#	HetrixTools Server Monitoring Agent - Install Script
#	version 1.6.0
#	Copyright 2015 - 2023 @  HetrixTools
#	For support, please open a ticket on our website https://hetrixtools.com
#
#
#		DISCLAIMER OF WARRANTY
#
#	The Software is provided "AS IS" and "WITH ALL FAULTS," without warranty of any kind, 
#	including without limitation the warranties of merchantability, fitness for a particular purpose and non-infringement. 
#	HetrixTools makes no warranty that the Software is free of defects or is suitable for any particular purpose. 
#	In no event shall HetrixTools be responsible for loss or damages arising from the installation or use of the Software, 
#	including but not limited to any indirect, punitive, special, incidental or consequential damages of any character including, 
#	without limitation, damages for loss of goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages or losses. 
#	The entire risk as to the quality and performance of the Software is borne by you, the user.
#
#

# Set PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Check if install script is run by root
echo "Checking root privileges..."
if [ "$EUID" -ne 0 ]
  then echo "ERROR: Please run the install script as root."
  exit
fi
echo "... done."

# Fetch Server Unique ID
SID=$1

# Make sure SID is not empty
echo "Checking Server ID (SID)..."
if [ -z "$SID" ]
	then echo "ERROR: First parameter missing."
	exit
fi
echo "... done."

# Check if user has selected to run agent as 'root' or as 'hydrabank' user
if [ -z "$2" ]
	then echo "ERROR: Second parameter missing."
	exit
fi

# Check if system has crontab and wget
echo "Checking for crontab and wget..."
command -v crontab >/dev/null 2>&1 || { echo "ERROR: Crontab is required to run this agent." >&2; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "ERROR: wget is required to run this agent." >&2; exit 1; }
echo "... done."

# Remove old agent (if exists)
echo "Checking if there's any old agent already installed..."
if [ -d /opt/hydrabank/agents/ ]
then
	echo "Old agent found, deleting it..."
	rm -rf /opt/hydrabank/agents/
else
	echo "No old agent found..."
fi
echo "... done."

# Creating agent folder
echo "Creating the agent folder..."
mkdir -p /opt/hydrabank/agents/
echo "... done."

# Fetching new agent
echo "Fetching the new agent..."
wget -t 1 -T 30 -qO /opt/hydrabank/agents/emberwood_agent.sh https://scripts.hydrabank.systems/emberwood_agent.sh
echo "... done."

# Inserting Server ID (SID) into the agent config
echo "Inserting Server ID (SID) into agent config..."
sed -i "s/SIDPLACEHOLDER/$SID/" /opt/hydrabank/agents/emberwood_agent.sh
echo "... done."

# Check if any services are to be monitored
echo "Checking if any services should be monitored..."
if [ "$3" != "0" ]
then
	echo "Services found, inserting them into the agent config..."
	sed -i "s/CheckServices=\"\"/CheckServices=\"$3\"/" /opt/hydrabank/agents/emberwood_agent.sh
fi
echo "... done."

# Check if software RAID should be monitored
echo "Checking if software RAID should be monitored..."
if [ "$4" -eq "1" ]
then
	echo "Enabling software RAID monitoring in the agent config..."
	sed -i "s/CheckSoftRAID=0/CheckSoftRAID=1/" /opt/hydrabank/agents/emberwood_agent.sh
fi
echo "... done."

# Check if Drive Health should be monitored
echo "Checking if Drive Health should be monitored..."
if [ "$5" -eq "1" ]
then
	echo "Enabling Drive Health monitoring in the agent config..."
	sed -i "s/CheckDriveHealth=0/CheckDriveHealth=1/" /opt/hydrabank/agents/emberwood_agent.sh
fi
echo "... done."

# Check if 'View running processes' should be enabled
echo "Checking if 'View running processes' should be enabled..."
if [ "$6" -eq "1" ]
then
	echo "Enabling 'View running processes' in the agent config..."
	sed -i "s/RunningProcesses=0/RunningProcesses=1/" /opt/hydrabank/agents/emberwood_agent.sh
fi
echo "... done."

# Check if any ports to monitor number of connections on
echo "Checking if any ports to monitor number of connections on..."
if [ "$7" != "0" ]
then
	echo "Ports found, inserting them into the agent config..."
	sed -i "s/ConnectionPorts=\"\"/ConnectionPorts=\"$7\"/" /opt/hydrabank/agents/emberwood_agent.sh
fi
echo "... done."

# Killing any running hetrixtools agents
echo "Making sure no agent scripts are currently running..."
ps aux | grep -ie emberwood_agent.sh | awk '{print $2}' | xargs kill -9
echo "... done."

# Checking if hetrixtools user exists
echo "Checking if user already exists..."
if id -u hydrabank >/dev/null 2>&1
then
	echo "The hydrabank user already exists, killing its processes..."
	pkill -9 -u `id -u hydrabank`
	echo "Deleting hydrabank user..."
	userdel hydrabank
	echo "Creating the new hydrabank user..."
	useradd hydrabank -r -d /opt/hydrabank -s /bin/false
	echo "Assigning permissions for the hetrixtools user..."
	chown -R hydrabank:hydrabank /opt/hydrabank
	chmod -R 700 /opt/hydrabank
else
	echo "The hydrabank user doesn't exist, creating it now..."
	useradd hydrabank -r -d /opt/hydrabank -s /bin/false
	echo "Assigning permissions for the hydrabank user..."
	chown -R hydrabank:hydrabank /opt/hydrabank
	chmod -R 700 /opt/hydrabank
fi
echo "... done."

# Removing old cronjob (if exists)
echo "Removing any old hydrabank cronjob, if exists..."
crontab -u root -l | grep -v 'emberwood_agent.sh'  | crontab -u root - >/dev/null 2>&1
crontab -u hydrabank -l | grep -v 'emberwood_agent.sh'  | crontab -u hydrabank - >/dev/null 2>&1
echo "... done."

# Setup the new cronjob to run the agent either as 'root' or as 'hetrixtools' user, depending on client's installation choice.
# Default is running the agent as 'hetrixtools' user, unless chosen otherwise by the client when fetching the installation code from the hetrixtools website.
if [ "$2" -eq "1" ]
then
	echo "Setting up the new cronjob as 'root' user..."
	crontab -u root -l 2>/dev/null | { cat; echo "* * * * * bash /opt/hydrabank/agents/emberwood_agent.sh >> /opt/hydrabank/logs/emberwood_cron.log 2>&1"; } | crontab -u root - >/dev/null 2>&1
else
	echo "Setting up the new cronjob as 'hydrabank' user..."
	crontab -u hydrabank -l 2>/dev/null | { cat; echo "* * * * * bash /opt/hydrabank/agents/emberwood_agent.sh >> /opt/hydrabank/logs/emberwood_cron.log 2>&1"; } | crontab -u hetrixtools - >/dev/null 2>&1
fi
echo "... done."

# Cleaning up install file
echo "Cleaning up the installation file..."
if [ -f $0 ]
then
    rm -f $0
fi
echo "... done."

# Let HetrixTools platform know install has been completed
echo "Letting Hydrabank platform know the installation has been completed..."
POST="v=install&s=$SID"
wget -t 1 -T 30 -qO- --post-data "$POST" https://api.hydride.dev/api/v1/metrics/ &> /dev/null
echo "... done."

# Start the agent
if [ "$2" -eq "1" ]
then
	echo "Starting the agent under the 'root' user..."
	bash /opt/hydrabank/agents/emberwood_agent.sh > /dev/null 2>&1 &
else
	echo "Starting the agent under the 'hydrabank' user..."
	sudo -u hydrabank bash /opt/hydrabank/agents/emberwood_agent.sh > /dev/null 2>&1 &
fi
echo "... done."

# All done
echo "Hydrabank Emberwood agent installation completed."
