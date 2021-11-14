BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

print_banner() {
cat<<EOF
   _____            ____           __        ____
  / ___/__  _______/  _/___  _____/ /_____ _/ / /__  _____
  \__ \/ / / / ___// // __ \/ ___/ __/ __ \`/ / / _ \/ ___/
 ___/ / /_/ (__  )/ // / / (__  ) /_/ /_/ / / /  __/ /
/____/\__, /____/___/_/ /_/____/\__/\__,_/_/_/\___/_/
     /____/
                                                  ~xSlendiX

EOF
}

logd() {
	echo -e "$BLUE :: $NC$@"
}

logw() {
	echo -e "$YELLOW :: $NC$@"
}

loge() {
	echo -e "$RED :: $NC$@"
}

log() {
	logd "$@"
}

reboot_to() {
	[ -n "$@" ] && echo "$@"
	echo "Rebooting in 3" && sleep 1
	echo "Rebooting in 2" && sleep 1
	echo "Rebooting in 1" && sleep 1
	reboot now
}

