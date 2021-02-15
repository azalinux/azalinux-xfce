#!/bin/bash -x

set -e
set -u

sh cores.sh
#xdg-user-dirs-update

sudo pacman -Syuu --noconfirm --needed
sudo pacman -S --noconfirm --needed arch-install-scripts
sudo pacman -S --noconfirm --needed os-prober
sudo pacman -S --noconfirm --needed openssh
sudo systemctl enable sshd
#sudo pacman -S --noconfirm --needed dhcpcd


sudo pacman -S xfce4 xfce4-goodies --noconfirm --needed
sudo pacman -S --noconfirm --needed xfce4-notifyd
sudo pacman -S --noconfirm --needed xorg
sudo pacman -S --noconfirm --needed xf86-video-amdgpu
sudo pacman -S --noconfirm --needed lightdm lightdm-gtk-greeter
sudo pacman -S --noconfirm --needed xf86-input-vmmouse xf86-video-vmware mesa 
sudo pacman -S --noconfirm --needed firewalld

sudo pacman -S adobe-source-sans-pro-fonts --noconfirm --needed
sudo pacman -S cantarell-fonts --noconfirm --needed
sudo pacman -S noto-fonts --noconfirm --needed
sudo pacman -S terminus-font --noconfirm --needed
sudo pacman -S ttf-bitstream-vera --noconfirm --needed
sudo pacman -S ttf-dejavu --noconfirm --needed
sudo pacman -S ttf-droid --noconfirm --needed
sudo pacman -S ttf-inconsolata --noconfirm --needed
sudo pacman -S ttf-liberation --noconfirm --needed
sudo pacman -S ttf-roboto --noconfirm --needed
sudo pacman -S ttf-ubuntu-font-family --noconfirm --needed
sudo pacman -S tamsyn-font --noconfirm --needed

sudo pacman -S pulseaudio --noconfirm --needed
sudo pacman -S pulseaudio-alsa --noconfirm --needed
sudo pacman -S pavucontrol  --noconfirm --needed
sudo pacman -S alsa-utils alsa-plugins alsa-lib alsa-firmware --noconfirm --needed
sudo pacman -S gstreamer --noconfirm --needed
sudo pacman -S gst-plugins-good gst-plugins-bad gst-plugins-base gst-plugins-ugly --noconfirm --needed
sudo pacman -S volumeicon --noconfirm --needed
sudo pacman -S playerctl --noconfirm --needed

# installing bluetooth software
sudo pacman -S --noconfirm --needed pulseaudio-bluetooth
sudo pacman -S --noconfirm --needed bluez
sudo pacman -S --noconfirm --needed bluez-libs
sudo pacman -S --noconfirm --needed bluez-utils
sudo pacman -S --noconfirm --needed blueberry

sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

sudo pacman -S --noconfirm --needed cups cups-pdf
sudo pacman -S ghostscript gsfonts gutenprint --noconfirm --needed
sudo pacman -S gtk3-print-backends --noconfirm --needed
sudo pacman -S libcups --noconfirm --needed
sudo pacman -S hplip --noconfirm --needed
sudo pacman -S system-config-printer --noconfirm --needed

sudo systemctl enable cups.service

sudo pacman -S --noconfirm --needed baobab
sudo pacman -S --noconfirm --needed accountsservice
sudo pacman -S --noconfirm --needed ffmpegthumbnailer
sudo pacman -S --noconfirm --needed gnome-disk-utility
sudo pacman -S --noconfirm --needed gnome-keyring

sudo pacman -S --noconfirm --needed curl
sudo pacman -S --noconfirm --needed nano
sudo pacman -S --noconfirm --needed dmidecode
sudo pacman -S --noconfirm --needed glances
sudo pacman -S --noconfirm --needed clamtk
sudo pacman -S --noconfirm --needed brasero
sudo pacman -S --noconfirm --needed sysstat
sudo pacman -S --noconfirm --needed screenfetch
sudo pacman -S --noconfirm --needed net-tools
sudo pacman -S --noconfirm --needed lm_sensors
sudo pacman -S --noconfirm --needed hexchat
sudo pacman -S --noconfirm --needed gimp
sudo pacman -S --noconfirm --needed grub-customizer 
sudo pacman -S --noconfirm --needed wget
sudo pacman -S --noconfirm --needed net-tools
sudo pacman -S --noconfirm --needed htop
sudo pacman -S --noconfirm --needed gtop
sudo pacman -S --noconfirm --needed gparted
sudo pacman -S --noconfirm --needed simplescreenrecorder
sudo pacman -S --noconfirm --needed filezilla
#sudo pacman -S --noconfirm --needed atom
sudo pacman -S --noconfirm --needed ipset
sudo pacman -S --noconfirm --needed geany
sudo pacman -S --noconfirm --needed meld
sudo pacman -S --noconfirm --needed catfish
sudo pacman -S --noconfirm --needed unace unrar zip unzip sharutils uudeview arj cabextract file-roller
sudo pacman -S --noconfirm --needed firefox
sudo pacman -S --noconfirm --needed thunderbird
sudo pacman -S --noconfirm --needed qbittorrent
sudo pacman -S --noconfirm --needed neofetch
sudo pacman -S --noconfirm --needed chromium
sudo pacman -S --noconfirm --needed libreoffice-fresh
sudo pacman -S --noconfirm --needed mpv
sudo pacman -S --noconfirm --needed breeze-icons
sudo pacman -S --noconfirm --needed elementary-icon-theme
sudo pacman -S --noconfirm --needed adapta-gtk-theme
sudo pacman -S --noconfirm --needed network-manager-applet
sudo pacman -S --noconfirm --needed p7zip


#sh sddm.sh
sh wallpaper.sh

sh samba_install.sh

sh trizen.sh

sh lightdm.sh

echo "### Installing Vivaldi Snapshot ###"
#sh install-vivaldi.sh

trizen -S --noconfirm --needed --noedit pamac-aur-git
#trizen -S --noconfirm --needed --noedit google-chrome-dev
trizen -S --noconfirm --needed --noedit ocs-url
trizen -S --noconfirm --needed --noedit thunar-shares-plugin
#trizen -S --noconfirm --needed --noedit sweet-folders-icons-git
#trizen -S --noconfirm --needed --noedit starlabstheme-gtk-git
#trizen -S --noconfirm --needed --noedit vivaldi
#trizen -S --noconfirm --needed --noedit vivaldi-codecs-ffmpeg-extra-bin
trizen -S --noconfirm --needed --noedit realvnc-vnc-server
trizen -S --noconfirm --needed --noedit realvnc-vnc-viewer
#trizen -S --noconfirm --needed --noedit vlc-nightly
trizen -S --noconfirm --needed --noedit inxi-git

#sh xfce_custom_desktop.sh

#sudo /usr/bin/vnclicense -add P98BK-34AF4-V2K63-TMBH8-BYNRA

sudo systemctl enable vncserver-x11-serviced

sudo systemctl enable NetworkManager


