#!/bin/sh
# This script was written by Frank Caviggia
# Last update was 16 Nov 2015
#
# Script: ipa-pam-configuration.sh (system-hardening)
# Description: RHEL 7 Hardening Supplemental to SSG, configures PAM with sssd if system is registered with IdM.
# License: GPLv2
# Copyright: Frank Caviggia, 2016
# Author: Frank Caviggia <fcaviggia (at) gmail.com>

# Backup originial configuration
if [ ! -e /etc/pam.d/system-auth-local.orig ]; then
  cp /etc/pam.d/system-auth-local /etc/pam.d/system-auth-local.orig
fi
if [ ! -e /etc/pam.d/password-auth-local.orig ]; then
  cp /etc/pam.d/password-auth-local /etc/pam.d/password-auth-local.orig
fi

# Deploy Configuruation
cat <<EOF > /etc/pam.d/system-auth-local
#%PAM-1.0
auth required pam_env.so
auth required pam_lastlog.so inactive=35
auth required pam_faillock.so preauth silent audit deny=3 even_deny_root root_unlock_time=900 unlock_time=604800 fail_interval=900
auth sufficient pam_unix.so try_first_pass
auth sufficient pam_sss.so use_first_pass
auth [default=die] pam_faillock.so authfail audit deny=3 even_deny_root root_unlock_time=900 unlock_time=604800 fail_interval=900
auth sufficient pam_faillock.so authsucc audit deny=3 even_deny_root root_unlock_time=900 unlock_time=604800 fail_interval=900
auth requisite pam_succeed_if.so uid >= 1000 quiet
auth required pam_deny.so

account required pam_faillock.so
account required pam_unix.so
account required pam_lastlog.so inactive=35
account sufficient pam_localuser.so
account sufficient pam_succeed_if.so uid < 1000 quiet
account [default=bad success=ok user_unknown=ignore] pam_sss.so
account required pam_permit.so

# Password Quality now set in /etc/security/pwquality.conf
password required pam_pwqaulity.so retry=3
password sufficient pam_unix.so sha512 shadow try_first_pass use_authtok remember=24
password sufficient pam_sss.so use_authtok
password required pam_deny.so

session required pam_lastlog.so showfailed
session optional pam_keyinit.so revoke
session required pam_limits.so
-session optional pam_systemd.so
session optional pam_oddjob_mkhomedir.so umask=0077
session [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session required pam_unix.so
session optional pam_sss.so
EOF
ln -sf /etc/pam.d/system-auth-local /etc/pam.d/system-auth


cat <<EOF > /etc/pam.d/password-auth-local
#%PAM-1.0
auth required pam_env.so
auth required pam_lastlog.so inactive=35
auth required pam_faillock.so preauth silent audit deny=3 even_deny_root root_unlock_time=900 unlock_time=604800 fail_interval=900
auth sufficient pam_unix.so try_first_pass
auth sufficient pam_sss.so use_first_pass
auth [default=die] pam_faillock.so authfail audit deny=3 even_deny_root root_unlock_time=900 unlock_time=604800 fail_interval=900
auth sufficient pam_faillock.so authsucc audit deny=3 even_deny_root root_unlock_time=900 unlock_time=604800 fail_interval=900
auth requisite pam_succeed_if.so uid >= 1000 quiet
auth required pam_deny.so

account required pam_faillock.so
account required pam_unix.so
account required pam_lastlog.so inactive=35
account sufficient pam_localuser.so
account sufficient pam_succeed_if.so uid < 1000 quiet
account [default=bad success=ok user_unknown=ignore] pam_sss.so
account required pam_permit.so

# Password Quality now set in /etc/security/pwquality.conf
password required pam_pwqaulity.so retry=3
password sufficient pam_unix.so sha512 shadow try_first_pass use_authtok remember=24
password sufficient pam_sss.so use_authtok
password required pam_deny.so

session required pam_lastlog.so showfailed
session optional pam_keyinit.so revoke
session required pam_limits.so
-session optional pam_systemd.so
session optional pam_oddjob_mkhomedir.so umask=0077
session [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session required pam_unix.so
session optional pam_sss.so
EOF
ln -sf /etc/pam.d/password-auth-local /etc/pam.d/password-auth

exit 0
