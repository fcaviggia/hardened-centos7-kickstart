#!/bin/bash
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
		v)
			echo "$0: HARDENED CentOS 7 DVD CREATOR Version: 1.2"
			;;
		h)
			usage
			exit 0
			;;
		q)
			QUIET=1
			;;
		?)
			echo "ERROR: Invalid Option Provided!"
			echo
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "$1" ]; then
	usage
	exit 1
fi

# Check for root user
if [[ $EUID -ne 0 ]]; then
	if [ -z "$QUIET" ]; then
		echo
		tput setaf 1;echo -e "\033[1mThis script will attempt to use sudo execute commands as root!\033[0m";tput sgr0
		SUDO="sudo -u root"
	else
		SUDO="sudo -nu root"
	fi
else
	SUDO=""
fi

# Check for required packages
which genisoimage &> /dev/null
if [ $? -ne 0 ]; then
	$SUDO yum install -y genisoimage || $SUDO apt-get install -y genisoimage || {
		which genisoimage || exit 1
	}
fi

which isohybrid &> /dev/null
if [ $? -ne 0 ]; then
	$SUDO yum install -y syslinux || $SUDO apt-get install -y syslinux || {
		which syslinux || exit 1
	}
fi

which implantisomd5 &> /dev/null
if [ $? -ne 0 ]; then
	$SUDO yum install -y isomd5sum || $SUDO apt-get install -y isomd5sum || {
		which implantisomd5 || exit 1
	}
fi

# Determine if DVD is Bootable
`file $1 | grep -q -e "9660.*boot" -e "x86 boot"`
if [[ $? -eq 0 ]]; then
	echo "Mounting CentOS DVD Image..."
	mkdir -p $DIR/original-mnt
	mkdir $DIR/hardened-tmp
	$SUDO mount -o loop $1 $DIR/original-mnt
	echo "Done."
	if [ ! -e $DIR/original-mnt/.treeinfo ]; then
		echo "ERROR: Image is not CentOS"
		exit 1
	fi

	echo -n "Copying CentOS DVD Image..."
	cp -a $DIR/original-mnt/* $DIR/hardened-tmp/
	cp -a $DIR/original-mnt/.*info $DIR/hardened-tmp/
	echo " Done."
	$SUDO umount $DIR/original-mnt
	rm -rf $DIR/original-mnt
else
	echo "ERROR: ISO image is not bootable."
	exit 1
fi

echo -n "Modifying CentOS DVD Image..."
cp -a $DIR/config/* $DIR/hardened-tmp/
echo " Done."
echo "Remastering CentOS DVD Image..."
cd $DIR/hardened-tmp
chmod u+w isolinux/isolinux.bin
find . -name TRANS.TBL -exec rm -f '{}' \; 
genisoimage -l -r -J -V "CentOS 7 x86_64" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o $DIR/hardened-centos7-x86_64.iso -eltorito-alt-boot -e images/efiboot.img -no-emul-boot .

cd $DIR
rm -rf $DIR/hardened-tmp
echo "Done."

echo "Signing CentOS DVD Image..."
/usr/bin/isohybrid --uefi $DIR/hardened-centos7-x86_64.iso &> /dev/null
/usr/bin/implantisomd5 $DIR/hardened-centos7-x86_64.iso
echo "Done."

echo "DVD Created. [hardened-centos7-x86_64.iso]"

exit 0
