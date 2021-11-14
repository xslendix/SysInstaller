#!/bin/sh

. ./common.sh

if [ "$(whoami)" != "root" ]; then
	echo "This script needs to be ran as root."
	exit
fi

echo 'As a safety measure, please type "Yes, execute please"'
read safety
if [ "$safety" != "Yes, execute please" ]; then
	log Installer cancelled.
	exit
fi

print_banner

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

log Detecting distribution

export distro=

[ -f "/etc/arch-release" ] && distro=arch

if [ -z "$distro" ]; then
	loge No supported distribution detected!
	exit 1
fi

sh preinstall.sh
if [ "$distro" = 'arch' ]; then
	arch-chroot /mnt /root/SysInstaller/1_setup_arch.sh
	username=$(cat /mnt/root/SysInstaller/.username)
	arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/SysInstaller/2_user_arch.sh
	arch-chroot /mnt /root/SysInstaller/3_post_setup_arch.sh
fi

