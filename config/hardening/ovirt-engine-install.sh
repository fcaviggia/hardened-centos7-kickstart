#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 07 Feb 2016
#
# Script: ovirt-master-setup.sh
# Description: Installs and preforms setup Ovirt 3.x (ovirt-engine)
# License: GPLv2
# Copyright: Frank Caviggia, 2016

# Check for root user
if [[ $EUID -ne 0 ]]; then
	tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	exit 1
fi

echo -e "\033[3m\033[1mOvirt Engine Setup Script\033[0m\033[0m"
echo
echo -e "\033[1mThis script downloads and starts the Ovirt Manager.\033[0m"
echo
echo -ne "\033[1mDo you want to continue?\033[0m [y/n]: "
while read a; do
case "$a" in
	y|Y) break;;
	n|N) exit 1;;
	*) echo -n "[y/n]: ";;
esac
done

# Install ovirt-engine-setup and dependancies
/bin/yum install ovirt-engine-setup nfs-utils nfs4-acl-tools -y

# Setup Ovirt Manager
/bin/engine-setup

# Configure Firewall
/root/iptables.sh --ovirt

# Enable and Start Services
systemctl enable ovrit-engine
systemctl enable httpd
systemctl enable iptables
systemctl restart httpd
systemctl restart iptables

exit 0
