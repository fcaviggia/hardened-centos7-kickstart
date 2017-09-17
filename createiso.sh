#!/bin/bash
###############################################################################
# HARDENED CentOS 7 DVD CREATOR
#
# This script was written by Frank Caviggia
# Last update was 16 September 2017
#
# Author: Frank Caviggia (fcaviggia@gmail.com)
# Copyright: Frank Caviggia, (c) 2017
# Version: 1.3
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

Requires CentOS 7.4+ (1708)

EOF
}

while getopts ":vhq" OPTION; do
	case $OPTION in
		v)
			echo "$0: HARDENED CentOS 7 DVD CREATOR Version: 1.2.1"
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
`file $1 | grep -q -e "9660.*boot" -e "x86 boot" -e "DOS/MBR boot"`
if [[ $? -eq 0 ]]; then
	echo "Mounting CentOS DVD Image..."
	mkdir -p $DIR/original-mnt
	mkdir $DIR/hardened-tmp
	$SUDO mount -o loop $1 $DIR/original-mnt
	if [[ -e $DIR/original-mnt/.discinfo && -e $DIR/original-mnt/.treeinfo ]]; then
		CENTOS_VERSION=$(grep "7." $DIR/original-mnt/.discinfo)
		MAJOR=$(echo $CENTOS_VERSION | awk -F '.' '{ print $1 }')
		MINOR=$(echo $CENTOS_VERSION | awk -F '.' '{ print $2 }')
		BUILD=$(ls $DIR/original-mnt/Packages/centos-release* | awk -F '.' '{ print $2 }')
		ARCH=$(ls $DIR/original-mnt/Packages/centos-release* | awk -F '.' '{ print $5 }')
		HARDENED_ISO="CentOS-$MAJOR.$MINOR-$ARCH-DVD-$BUILD-hardened.iso"
		if [[ $MAJOR -ne 7 ]]; then
			echo "ERROR: Image is not CentOS 7.4+"
			$SUDO umount $DIR/original-mnt
			$SUDO rm -rf $DIR/original-mnt
			exit 1
		fi
		if [[ $MINOR -lt 4 ]]; then
			echo "ERROR: Image is not CentOS 7.4+"
			$SUDO umount $DIR/original-mnt
			$SUDO rm -rf $DIR/original-mnt
			exit 1
		fi
	else
		echo "ERROR: Image is not CentOS"
		$SUDO umount $DIR/original-mnt
		$SUDO rm -rf $DIR/original-mnt
		exit 1
	fi
	echo "Done."

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
genisoimage -l -r -J -V "CentOS 7 x86_64" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o $DIR/$HARDENED_ISO -eltorito-alt-boot -e images/efiboot.img -no-emul-boot .

cd $DIR
rm -rf $DIR/hardened-tmp
echo "Done."

echo "Signing CentOS DVD Image..."
/usr/bin/isohybrid --uefi $DIR/$HARDENED_ISO &> /dev/null
/usr/bin/implantisomd5 $DIR/$HARDENED_ISO
echo "Done."

echo "DVD Created. [$HARDENED_ISO]"

echo "Creating the DVD metadata file..."
FULL_USER_NAME=$(getent passwd "$(whoami)" | cut -d ':' -f 5)
CREATION_DATE=$(date --utc --rfc-2822)
SCRIPT_NAME=$(basename $0)
SCRIPT_VERSION=$(grep -iE "# +version" createiso.sh | tail -1 | cut -d ' ' -f 3)
ORIGINAL_ISO_HASH=$(sha256sum "$1")
HARDENED_ISO_HASH=$(sha256sum "$DIR"/"$HARDENED_ISO")
SCRIPT_HASH=$(sha256sum "$SCRIPT_NAME")
cat <<EOF > "$DIR"/"${HARDENED_ISO%.*}.info.txt"
  Prepared By: $FULL_USER_NAME
Creation Date: $CREATION_DATE

Compile Script: $SCRIPT_NAME
       Version: $SCRIPT_VERSION
          Hash: $SCRIPT_HASH
Project Source: hardened-centos7-kickstart
   Project URL: https://github.com/fcaviggia/hardened-centos7-kickstart

$ORIGINAL_ISO_HASH
$HARDENED_ISO_HASH

Mainline Downloads: https://www.centos.org/download/
 Rolling Downloads: https://buildlogs.centos.org/rolling/7/isos/x86_64/
EOF
echo "Done."

exit 0
