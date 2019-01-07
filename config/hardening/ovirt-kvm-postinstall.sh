#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 04 Dec 2018
#
# Script: ovirt-postinstall.sh
# Description: Losens Hardening settings temporarily to allow registration with RHEVM 3.x
# License: Apache License, Version 2.0
# Copyright: Frank Caviggia, 2018

# Check for root user
if [[ $EUID -ne 0 ]]; then
	tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	exit 1
fi

echo -e "\033[3m\033[1mOvirt Post-Install Script\033[0m\033[0m"

/usr/bin/oscap xccdf eval --profile stig-rhel7-server-upstream --remediate --results /root/`hostname`-ssg-results.xml  --cpe /usr/share/xml/scap/ssg/content/ssg-rhel7-cpe-dictionary.xml /usr/share/xml/scap/ssg/content/ssg-rhel7-xccdf.xml &> /dev/null

# Disallow Root Login
gpasswd -d root sshusers
sed -i "/^PermitRootLogin/ c\PermitRootLogin no" /etc/ssh/sshd_config
sed -e "/pam_succeed_if.so uid/s/^#//g" -i /etc/pam.d/password-auth

# Restart SSHD Service
systemctl restart sshd.service

# Remount /tmp Partition
mount -o remount,defaults /tmp

# Configure Firewall
/root/iptables.sh --kvm

# Restart Firewall
systemctl restart iptables

# Never Expire VDSM account
chage -m 0 -M 99999 -I -1 -E -1 vdsm

exit 0
