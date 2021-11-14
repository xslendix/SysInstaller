. /root/SysInstaller/common.sh

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

log "Cleaning up"
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

cd $pwd

echo "Done!"
reboot_to

