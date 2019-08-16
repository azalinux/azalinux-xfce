#!/bin/bash

set -e

sudo groupadd -r autologin
sudo gpasswd -a aza autologin

sudo wget https://raw.githubusercontent.com/azalinux/azalinux-xfce/master/lightdm.conf -O /etc/lightdm/lightdm.conf

sudo systemctl enable lightdm.service
sudo systemctl set-default graphical.target
