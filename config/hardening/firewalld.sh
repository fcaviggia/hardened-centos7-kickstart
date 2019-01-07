#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 05 December 2018
#
# Script: firewall-config.sh (system-hardening)
# Description: CentOS 7 FirewallD configuration for KVM and Ovirt-Attached profiles
# License: Apache License, Version 2.0
# Copyright: Frank Caviggia, 2018
# Author: Frank Caviggia <fcaviggi (at) gmail.com>

# USAGE STATEMENT
function usage() {
cat << EOF
usage: $0 [options]

  -h,--help	Show this message

  --http	Allows HTTP (80/tcp)
  --https	Allows HTTPS (443/tcp)
  --dns		Allows DNS (53/tcp/udp)
  --ntp		Allows NTP (123/tcp/udp)
  --dhcp	Allows DHCP (67,68/tcp/udp)
  --tftp	Allows TFTP (69/tcp/udp)
  --rsyslog	Allows RSYSLOG (514/tcp/udp)
  --kerberos	Allows Kerberos (88,464/tcp/udp)
  --ldap	Allows LDAP (389/tcp/udp)
  --ldaps	Allows LDAPS (636/tcp/udp)
  --nfsv4	Allows NFSv4 (2049/tcp)
  --iscsi	Allows iSCSI (3260/tcp)
  --samba       Allows Samba Services (137,138/udp;139,445/tcp)
  --mysql	Allows MySQL (3306/tcp)
  --postgresql	Allows PostgreSQL (5432/tcp)
  --kvm		Allows KVM Hypervisor (Ovirt-attached)
  --ipa		Allows FreeIPA/IdM Authentication Server
  --rhnsat      Allows Spacewalk/RHN Satellite Patch Server

Configures firewalld rules for CentOS.
 
EOF
}

# Get options
OPTS=`getopt -o h --long http,https,dns,ldap,ldaps,kvm,nfsv4,iscsi,idm,ipa,krb5,kerberos,rsyslog,dhcp,bootp,tftp,ntp,smb,samba,cifs,mysql,mariadb,postgres,postgresql,rhnsat,help -- "$@"`
if [ $? != 0 ]; then
	exit 1
fi
eval set -- "$OPTS"

while true ; do
    case "$1" in
	--http) HTTP=1 ; shift ;;
	--https) HTTPS=1 ; shift ;;
	--dns) DNS=1 ; shift ;;
	--dhcp) DHCP=1 ; shift ;;
	--ldap) LDAP=1 ; shift ;;
	--ldaps) LDAPS=1 ; shift ;;
	--kerberos) KERBEROS=1 ; shift ;;
	--idm) KERBEROS=1 ; LDAP=1; LDAPS=1; DNS=1; NTP=1; HTTPS=1; shift ;;
	--ipa) KERBEROS=1 ; LDAP=1; LDAPS=1; DNS=1; NTP=1; HTTPS=1; shift ;;
	--rhnsat) HTTP=1; HTTPS=1; RHNSAT=1; shift ;;
	--krb5) KERBEROS=1 ; shift ;;
	--kvm) KVM=1 ; shift ;;
	--ovirt) HTTPS=1; OVIRT=1 ; shift ;;
	--iscsi) ISCSI=1 ; shift ;;
	--nfsv4) NFSV4=1 ; shift ;;
	--tftp) TFTP=1 ; shift ;;
	--dhcp) DHCP=1 ; shift ;;
	--bootp) DHCP=1 ; shift ;;
	--ntp) NTP=1 ; shift ;;
	--smb) SAMBA=1 ; shift ;;
	--samba) SAMBA=1 ; shift ;;
	--cifs) SAMBA=1 ; shift ;;
	--mysql) MARIADB=1 ; shift ;;
	--mariadb) MARIADB=1 ; shift ;;
	--postgres) POSTGRESQL=1 ; shift ;;
	--postgresql) POSTGRESQL=1 ; shift ;;
	--rsyslog) RSYSLOG=1 ; shift ;;
        --) shift ; break ;;
        *) usage ; exit 0 ;;
    esac
done

# Check for root user
if [[ $EUID -ne 0 ]]; then
	tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	exit 1
fi

# Set Default Zone to DROP
sed -i '/DefaultZone=/c\DefaultZone=drop' /etc/firewalld/firewalld.conf

if [ ! -z $DNS ]; then
firewall-cmd --permanent --zone=public --add-service=dns
fi

if [ ! -z $DHCP ]; then
firewall-cmd --permanent --zone=public --add-service=dhcp
fi

if [ ! -z $TFTP ]; then
firewall-cmd --permanent --zone=public --add-service=tftp
fi

if [ ! -z $HTTP ]; then
#### HTTPD - Recommend forwarding traffic to HTTPS 443
####   Recommended Article: http://www.cyberciti.biz/tips/howto-apache-force-https-secure-connections.html
firewall-cmd --permanent --zone=public --add-service=http
fi

if [ ! -z $KERBEROS ]; then
#### Kerberos Authentication (IdM/IPA)
firewall-cmd --permanent --zone=public --add-service=kerberos
#### Kerberos Authentication - kpasswd (IdM/IPA)
firewall-cmd --permanent --zone=public --add-service=kpasswd
fi

if [ ! -z $NTP ]; then
#### NTP Server
firewall-cmd --permanent --zone=public --add-service=ntp
fi

if [ ! -z $LDAP ]; then
#### LDAP (IdM/IPA)
firewall-cmd --permanent --zone=public --add-service=ldap
fi

if [ ! -z $HTTPS ]; then
#### HTTPS
firewall-cmd --permanent --zone=public --add-service=ldaps
fi

if [ ! -z $RSYSLOG ]; then
#### RSYSLOG Server
firewall-cmd --permanent --zone=public --add-port=514/tcp
firewall-cmd --permanent --zone=public --add-port=514/udp
fi

if [ ! -z $LDAPS ]; then
#### LDAPS - LDAP via SSL (IdM/IPA)
firewall-cmd --permanent --zone=public --add-service=ldaps
fi

if [ ! -z $NFSV4 ]; then
#### NFSv4 Server
firewall-cmd --permanent --zone=public --add-port=2049/tcp
fi

if [ ! -z $ISCSI ]; then
#### iSCSI Server
firewall-cmd --permanent --zone=public --add-port=3260/tcp
fi

if [ ! -z $POSTGRESQL ]; then
#### PostgreSQL Server
firewall-cmd --permanent --zone=public --add-port=5432/tcp
fi

if [ ! -z $MARIADB ]; then
#### MariaDB/MySQL Server
firewall-cmd --permanent --zone=public --add-port=3306/tcp
fi

if [ ! -z $SAMBA ]; then
#### Samba/CIFS Server
firewall-cmd --permanent --zone=public --add-port=137/udp
firewall-cmd --permanent --zone=public --add-port=138/udp
firewall-cmd --permanent --zone=public --add-port=139/tcp
firewall-cmd --permanent --zone=public --add-port=445/tcp
fi

if [ ! -z $KVM ]; then
#### SPICE/VNC Client (KVM)
firewall-cmd --permanent --zone=public --add-port=5634-6166/tcp
#### KVM Virtual Desktop and Server Manager (VDSM) Service
firewall-cmd --permanent --zone=public --add-port=5432/tcp
#### KVM VM Migration
firewall-cmd --permanent --zone=public --add-port=16514/tcp
firewall-cmd --permanent --zone=public --add-port=49152-49216/tcp
fi

if [ ! -z $RHNSAT ]; then
#### RHN Satellite Push Service
firewall-cmd --permanent --zone=public --add-port=5222/tcp
firewall-cmd --permanent --zone=public --add-port=5269/tcp
fi

firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT_direct 0 -p tcp -m limit --limit 25/minute --limit-burst 100  -j ACCEPT

firewall-cmd --reload

exit 0
