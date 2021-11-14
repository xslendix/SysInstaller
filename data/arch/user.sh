. $HOME/SysInstaller/util/common.sh

log Installing AUR software
log Installing yay
cd
git clone --depth 1 'https://aur.archlinux.org/yay.git'
cd $HOME/yay
makepkg -si --noconfirm
cd

packages='autojump awesome-terminal-fonts dxvk-bin lightly-git lightlyshaders-git mangohud mangohud-common noto-fonts-emoji papirus-icon-theme plasma-pa ocs-url sddm-nordic-theme-git snapper-gui-git ttf-droid ttf-hack ttf-meslo ttf-roboto snap-pac'

for i in $packages; do
	yay -S --noconfirm $i
done

log Applying theme

export PATH=$PATH:~/.local/bin
mkdir -p ~/.local/bin
pip install konsave
curl -LO https://xslendi.xyz/profile.knsv
konsave -i profile.knsv
sleep 1
konsave -a profile
