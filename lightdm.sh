#!/bin/bash

set -e

sudo groupadd -r autologin
sudo gpasswd -a username autologin

#wget 

sudo systemctl enable lightdm.service
sudo systemctl set-default graphical.target
