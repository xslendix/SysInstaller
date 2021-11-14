. /root/SysInstaller/common.sh

log "Setting up networking"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager

log "Setting up mirrors"
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

cores=$(nproc)

log "Changing the makeflags for $cores cores."
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi

log "Setting language and locale to US"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone America/Chicago
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"

log "Setting keymap"
localectl --no-ask-password set-keymap us

log "Allowing the wheel group to execute commands with sudo"
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

log "Setting up parallel downloading"
sed -i 's/^#Para/Para/' /etc/pacman.conf

log "Enabling 32-bit libraries"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

log "Installing packages"

while IFS=, read -r package_name package_desc
do
	if [ -z "$package_desk"]; then 
		log "Installing $package_name"
	else
		log "Installing $package_desc ($package_name)"
	fi
	sudo pacman -S $package_name --noconfirm --needed
done < /root/SysInstaller/packages/arch.csv

log "Installing microcode, if available."
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		log "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		log "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac

log "Installing graphics drivers"
if lspci | grep -E "NVIDIA|GeForce"; then
	pacman -S nvidia --noconfirm --needed
	nvidia-xconfig
elif lspci | grep -E "Radeon"; then
	pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "Integrated Graphics Controller"; then
	pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

read -p 'Enter username: ' username
echo $username > $HOME/SysInstaller/.username

log "Creating user \"$username\""
useradd -m -G wheel,libvirt,network,rtkit,rfkill,kvm,audio,scanner -s /bin/bash $username
passwd $username
cp -R /root/SysInstaller /home/$username/SysInstaller
chown -R $username: /home/$username/SysInstaller

read -p 'Enter hostname (name of machine): ' hostname
echo $hostname > /etc/hostname

