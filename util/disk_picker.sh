RED='\033[1;31m'
NC='\033[0m' # No Color

__print_disks() {
	lsblk -d | awk '/ [0-9]*:/' | awk 'BEGIN{print "DISK\t\tSIZE\n-------\t\t-------"} {print $1"\t\t"$4}'
}

__print_disks

while true; do
	printf "Which disk do you wish to use? Type 'p' to print the listing again.\n? "
	read __disk

	if [ "$__disk" = "p" ]; then
		__print_disks
	else
		if ! [ -e "/dev/$__disk" ]; then
			echo "Invalid disk. Try again."
		else
			echo -e "${RED}WARNING! Proceeding will delete all data on \"$__disk\".$NC"
			read -p "Do you wish to continue? [y/N]: " yn

			case $yn in
				[Yy]* ) break;;
				* ) ;;
			esac
		fi
	fi

done

export DISK="/dev/$__disk"

