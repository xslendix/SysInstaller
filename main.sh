#!/bin/sh

. ./util/common.sh

if [ "$(whoami)" != "root" ]; then
	echo "This script needs to be ran as root."
	exit
fi

print_banner

echo 'As a safety measure, please type "Yes, execute please"'

read safety
if [ "$safety" != "Yes, execute please" ]; then
	log Installer cancelled.
	exit
fi

export SCRIPT=$(readlink -f "$0")
export SCRIPTPATH=$(dirname "$SCRIPT")

log Detecting distribution

export distro=

[ -f "/etc/arch-release" ] && distro=arch

if [ -z "$distro" ]; then
	loge No supported distribution detected!
	exit 1
fi

export syschroot=

if [ "$distro" = 'arch' ]; then
    syschroot=arch-chroot
    pacman -Sy
fi

if [ -z "$syschroot" ]; then
    loge "No adequate chroot command detected. Exiting."
    exit 1
fi

sh data/$distro/preinstall.sh
log "Preinstall stage done"
$syschroot /mnt /root/SysInstaller/data/$distro/setup.sh

username=$(cat /mnt/root/SysInstaller/.username)
$syschroot /mnt /usr/bin/runuser -u $username -- /home/$username/SysInstaller/data/$distro/user.sh
log "User stage done"
$syschroot /mnt /root/SysInstaller/data/$distro/postinstall.sh
log "Postinstall stage done"

echo -e "\nInstallation done! Please remove the installation medium and press ENTER to reboot."
read
reboot_to
