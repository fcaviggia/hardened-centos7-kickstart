#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 07 Feb 2016
#
# Script: ovirt-preinstall.sh
# Description: Losens Hardening settings temporarily to allow registration with Ovirt 3.x
# License: Apache License, Version 2.0
# Copyright: Frank Caviggia, 2018

# Check for root user
if [[ $EUID -ne 0 ]]; then
	tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	exit 1
fi

echo -e "\033[3m\033[1mOvirt Pre-Install Script\033[0m\033[0m"
echo
echo -e "\033[1mThis script losens hardening settings to allow Ovirt Manager to attach a system.\033[0m"
echo
echo -ne "\033[1mDo you want to continue?\033[0m [y/n]: "
while read a; do
case "$a" in
	y|Y) break;;
	n|N) exit 1;;
	*) echo -n "[y/n]: ";;
esac
done

# Permit Root Login
usermod -a -G sshusers root
sed -i "/^PermitRootLogin/ c\PermitRootLogin yes" /etc/ssh/sshd_config
sed -e "/pam_succeed_if.so uid/s/^/#/g" -i /etc/pam.d/password-auth

# Restart SSHD Service
systemctl restart sshd.service

# Remount /tmp Partition
mount -o remount,exec /tmp

# UMASK 0022 for root to allow VDSMD configuration
if [ $(grep -c "umask 0022" /root/.bashrc) -eq 0 ]; then
	echo "umask 0022" >> /root/.bashrc
fi

# Fix Settings in /etc/yum.conf
sed -i "s/gpgcheck=1/gpgcheck=0/g" /etc/yum.conf
sed -i "s/localpkg_gpgcheck=1/localpkg_gpgcheck=0/g" /etc/yum.conf
sed -i "s/repo_gpgcheck=1/repo_gpgcheck=0/g" /etc/yum.conf

# Install vdsm and dependancies
/bin/yum install vdsm -y

# Configure firewall
/root/iptables.sh --kvm
systemctl restart iptables

# Restore Settings in /etc/yum.conf
sed -i "s/gpgcheck=0/gpgcheck=1/g" /etc/yum.conf
sed -i "s/localpkg_gpgcheck=0/localpkg_gpgcheck=1/g" /etc/yum.conf
sed -i "s/repo_gpgcheck=0/repo_gpgcheck=1/g" /etc/yum.conf

exit 0
