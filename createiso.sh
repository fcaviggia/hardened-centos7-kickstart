#!/bin/sh
###############################################################################
# HARDENED CentOS 7 DVD CREATOR
#
# This script was written by Frank Caviggia
# Last update was 23 July 2016
#
# Author: Frank Caviggia (fcaviggia@gmail.com)
# Copyright: Frank Caviggia, (c) 2016
# Version: 1.2
# License: GPLv2
# Description: Creates embedded kickstart from CentOS ISO that can preform
#              a hardened installation based on DISA STIG
###############################################################################

# GLOBAL VARIABLES
DIR=`pwd`

# USAGE STATEMENT
function usage() {
cat << EOF
usage: $0 centos-7.X-x86_64-dvd.iso

EOF
}

while getopts ":vhq" OPTION; do
	case $OPTION in
		h)
			usage
			exit 0
			;;
		?)
			echo "ERROR: Invalid Option Provided!"
			echo
			usage
			exit 1
			;;
	esac
done

# Check for root user
if [[ $EUID -ne 0 ]]; then
	if [ -z "$QUIET" ]; then
		echo
		tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	fi
	exit 1
fi

# Check for required packages
rpm -q genisoimage &> /dev/null
if [ $? -ne 0 ]; then
	yum install -y genisoimage
fi

rpm -q isomd5sum &> /dev/null
if [ $? -ne 0 ]; then
	yum install -y isomd5sum
fi

# Determine if DVD is Bootable
`file $1 | grep 9660 | grep -q bootable`
if [[ $? -eq 0 ]]; then
	echo "Mounting CentOS DVD Image..."
	mkdir -p /centos
	mkdir $DIR/centos-dvd
	mount -o loop $1 /centos
	echo "Done."
	if [ ! -e /centos/.treeinfo ]; then
		echo "ERROR: Image is not CentOS"
		exit 1
	fi

	echo -n "Copying CentOS DVD Image..."
	cp -a /centos/* $DIR/centos-dvd/
	cp -a /centos/.*info $DIR/centos-dvd/
	echo " Done."
	umount /centos
	rm -rf /centos
else
	echo "ERROR: ISO image is not bootable."
	exit 1
fi

echo -n "Modifying CentOS DVD Image..."
cp -a $DIR/config/* $DIR/centos-dvd/
echo " Done."
echo "Remastering CentOS DVD Image..."
cd $DIR/centos-dvd
chmod u+w isolinux/isolinux.bin
find . -name TRANS.TBL -exec rm '{}' \; 
genisoimage -l -r -J -V "CentOS 7 x86_64" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o $DIR/hardened-centos7-x86_64.iso .

cd $DIR
rm -rf $DIR/centos-dvd
echo "Done."

echo "Signing CentOS DVD Image..."
/usr/bin/implantisomd5 $DIR/hardened-centos7-x86_64.iso
echo "Done."

echo "DVD Created. [hardened-centos7-x86_64.iso]"

exit 0
