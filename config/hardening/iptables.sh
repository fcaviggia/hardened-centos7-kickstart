#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 2 June 2016
#
# Script: iptables.sh (system-hardening)
# Description: RHEL 7 iptables/ebtables configuration for KVM and Ovirt-Attached profiles
# License: GPL
# Copyright: Frank Caviggia, 2016
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
  --kvm		Allows KVM Hypervisor (RHEV-attached)
  --rhevm	Allows RHEV-M Specific Ports
  --ipa		Allows IPA/IdM Authentication Server

Configures iptables firewall rules for RHEL.
 
EOF
}

# Get options
OPTS=`getopt -o h --long http,https,dns,ldap,ldaps,kvm,rhevm,nfsv4,iscsi,idm,ipa,krb5,kerberos,rsyslog,dhcp,bootp,tftp,ntp,smb,samba,cifs,mysql,mariadb,postgres,postgresql,help -- "$@"`
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
	--krb5) KERBEROS=1 ; shift ;;
	--kvm) KVM=1 ; shift ;;
	--rhevm) HTTPS=1; RHEVM=1 ; shift ;;
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

# Check if iptables package is installed
if [ ! -e $(which iptables) ]; then
	echo "ERROR: The iptables package is not installed."
	exit 1
fi

# Backup originial configuration
if [ ! -e /etc/sysconfig/iptables.orig ]; then
	cp /etc/sysconfig/iptables /etc/sysconfig/iptables.orig
fi

# Basic rule set - allows established/related pakets and SSH through firewall
cat <<EOF > /etc/sysconfig/iptables
#################################################################################################################
# HARDENING SCRIPT IPTABLES Configuration
#################################################################################################################
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow Traffic that is established or related
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Allow ICMP (Ping)
-A INPUT -p icmp -j ACCEPT
# Allow Traffic on LOCALHOST/127.0.0.1
-A INPUT -i lo -j ACCEPT
#### SSH/SCP/SFTP
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
EOF

if [ ! -z $DNS ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### DNS Services (ISC BIND/IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
EOF
fi

if [ ! -z $DHCP ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### DHCP Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 67 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 67 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 68 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 68 -j ACCEPT
EOF
fi

if [ ! -z $TFTP ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### TFTP Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 69 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 69 -j ACCEPT
EOF
fi

if [ ! -z $HTTP ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### HTTPD - Recommend forwarding traffic to HTTPS 443
####   Recommended Article: http://www.cyberciti.biz/tips/howto-apache-force-https-secure-connections.html
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
EOF
fi

if [ ! -z $KERBEROS ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### Kerberos Authentication (IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 88 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 88 -j ACCEPT
#### Kerberos Authentication - kpasswd (IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 464 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 464 -j ACCEPT
EOF
fi

if [ ! -z $NTP ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### NTP Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 123 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 123 -j ACCEPT
EOF
fi

if [ ! -z $LDAP ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### LDAP (IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 389 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 389 -j ACCEPT
EOF
fi

if [ ! -z $HTTPS ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### HTTPS
-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
EOF
fi

if [ ! -z $RSYSLOG ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### RSYSLOG Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 514 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 514 -j ACCEPT
EOF
fi

if [ ! -z $LDAPS ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### LDAPS - LDAP via SSL (IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 636 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 636 -j ACCEPT
EOF
fi

if [ ! -z $NFSV4 ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### NFSv4 Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT
EOF
fi

if [ ! -z $ISCSI ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### iSCSI Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3260 -j ACCEPT
EOF
fi

if [ ! -z $POSTGRESQL ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### PostgreSQL Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 5432 -j ACCEPT
EOF
fi

if [ ! -z $MARIADB ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### MariaDB/MySQL Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT
EOF
fi

if [ ! -z $SAMBA ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### Samba/CIFS Server
-A INPUT -m udp -p udp --dport 137 -j ACCEPT
-A INPUT -m udp -p udp --dport 138 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT
EOF
fi

if [ ! -z $KVM ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### SPICE/VNC Client (KVM)
-A INPUT -m state --state NEW -m tcp -p tcp --match multiport --dports 5634:6166 -j ACCEPT
#### KVM Virtual Desktop and Server Manager (VDSM) Service
-A INPUT -m state --state NEW -m tcp -p tcp --dport 54321 -j ACCEPT
#### KVM VM Migration
-A INPUT -m state --state NEW -m tcp -p tcp --dport 16514 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --match multiport --dports 49152:49216 -j ACCEPT
EOF
fi

if [ ! -z $RHEVM ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### RHEVM (ActiveX Client)
-A INPUT -m state --state NEW -m tcp -p tcp --match multiport --dports 8006:8009 -j ACCEPT
#### RHEVM (ActiveX Client)
-A INPUT -m state --state NEW -m tcp -p tcp --match multiport --dports 8006:8009 -j ACCEPT
EOF
fi

cat <<EOF >> /etc/sysconfig/iptables
#################################################################################################################
# Block timestamp-request and timestamp-reply

-A INPUT -p ICMP --icmp-type timestamp-request -j DROP
-A INPUT -p ICMP --icmp-type timestamp-reply -j DROP
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF

exit 0
