#!/bin/bash
set -u

sudo mkdir /etc/sddm.conf.d
sudo wget "https://raw.githubusercontent.com/azalinux/azalinux-plasma/master/autologin.conf" -O /etc/sddm.conf.d/autologin.conf
sudo systemctl enable sddm
