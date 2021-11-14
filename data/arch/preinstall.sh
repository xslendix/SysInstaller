. $SCRIPTPATH/util/common.sh

log Setting up time
timedatectl set-ntp true

sed -i 's/#Color/Color/g' /etc/pacman.conf

pacman -S --noconfirm pacman-contrib

log Setting up parallel downloads
sed -i 's/^#Para/Para/' /etc/pacman.conf

country="$(curl -4 ifconfig.co/country-iso)"

log Setting up mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

log "Creating /mnt directory if it doesn't already exist"
mkdir -p /mnt

log "Installing prerequisites"
pacman -S --noconfirm gptfdisk btrfs-progs

log "Please select the disk to install Arch onto."
. $SCRIPTPATH/util/disk_picker.sh

log Selected disk: $DISK
echo "$DISK" > ./.disk

log Formatting disk

sgdisk -Z $DISK
sgdisk -a 2048 -o $DISK

log Partitioning disk
sgdisk -n 1::+1M   --typecode=1:ef02 --change-name=1:'BIOSBOOT' $DISK # 1st partition (BIOS Boot Partition)
sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'EFIBOOT'  $DISK # 2nd partition (UEFI Boot Partition)
sgdisk -n 3::-0    --typecode=3:8300 --change-name=3:'ROOT'     $DISK # 3rd partition (Root), default start, remaining
[ ! -d "/sys/firmware/efi" ] && sgdisk -A 1:set:2 $DISK

log Creating filesystems

case "$DISK" in
    *nvme*)  on_nvme=1 ;;
    *)      on_nvme=0 ;;
esac

if [ "$on_nvme" -eq 1 ]; then
    mkfs.vfat -F32 -n "EFIBOOT" "${DISK}p2"
    mkfs.btrfs -L "ROOT" "${DISK}p3" -f
    mount -t btrfs "${DISK}p3" /mnt
else
    mkfs.vfat -F32 -n "EFIBOOT" "${DISK}2"
    mkfs.btrfs -L "ROOT" "${DISK}3" -f
    mount -t btrfs "${DISK}3" /mnt
fi

ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt

log Mounting partitions

mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    reboot_to "Drive is not mounted and thus, installer cannot continue."
fi

log Installing base system
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed

log Generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

log Adding the finishing touches
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf

cp -R ${SCRIPTPATH} /mnt/root/SysInstaller
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

log Installing GRUB
if [ ! -d "/sys/firmware/efi" ]; then
    grub-install --boot-directory=/mnt/boot $DISK
fi

TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')

if [ "$TOTALMEM" -lt 8000000 ]; then
    log Low memory available. Creating swap
    mkdir /mnt/opt/swap
    chattr +C /mnt/opt/swap
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab
fi
