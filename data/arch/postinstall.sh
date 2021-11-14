. /root/SysInstaller/util/common.sh

log "GRUB EFI install"

DISK="$(cat /root/SysInstaller/.disk)"

if [ -d "/sys/firmware/efi" ]; then
    grub-install --efi-directory=/boot $DISK
fi
grub-mkconfig -o /boot/grub/grub.cfg

log "Enabling login manager"
systemctl enable sddm.service

log "Setting up SDDM theme"
cat <<EOF > /etc/sddm.conf
[Theme]
Current=Nordic
EOF

log "Enabling essential services"

systemctl enable cups.service
ntpd -qg
systemctl enable ntpd.service
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth
systemctl enable tlp

sudo rm -rf /root/SysInstaller

log "Cleaning up"
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

cd $pwd

flatpak update

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

cd ~

rm -rf ~/SysInstaller
