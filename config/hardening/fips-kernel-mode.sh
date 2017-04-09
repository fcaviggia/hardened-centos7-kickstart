#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 8 April 2017
#
# Script: fips-kernel-mod.sh (system-hardening)
# Description:Hardening - Configures kernel to FIPS mode
# License: GPLv2
# Copyright: Frank Caviggia, 2016
# Author: Frank Caviggia <fcaviggia (at) gmail.com>

########################################
# FIPS 140-2 Kernel Mode
########################################
sed -i 's/PRELINKING=yes/PRELINKING=no/g' /etc/sysconfig/prelink
prelink -u -a
dracut -f
BOOT=$(df /boot | tail -1 | awk '{ print $1 }')
/sbin/grubby --update-kernel=ALL --args="boot=${BOOT} fips=1"
/usr/bin/sed -i "s/quiet/quiet boot=${BOOT} fips=1" /etc/default/grub
