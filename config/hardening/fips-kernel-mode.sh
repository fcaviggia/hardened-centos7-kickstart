#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 17 August 2017
#
# Script: fips-kernel-mod.sh (system-hardening)
# Description:Hardening - Configures kernel to FIPS mode
# License: GPLv2
# Copyright: Frank Caviggia, 2016
# Author: Frank Caviggia <fcaviggia (at) gmail.com>

########################################
# FIPS 140-2 Kernel Mode
########################################
rpm -q prelink && sed -i '/^PRELINKING/s,yes,no,' /etc/sysconfig/prelink
rpm -q prelink && prelink -ua
dracut -f
BOOT="UUID=$(findmnt -no uuid /boot)"
/sbin/grubby --update-kernel=ALL --args="boot=${BOOT} fips=1"
/usr/bin/sed -i "s/quiet/quiet boot=${BOOT} fips=1" /etc/default/grub
