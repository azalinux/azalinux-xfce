#!/bin/bash -x

set -e
set -u

git clone https://aur.archlinux.org/trizen.git
cd trizen
makepkg -si --noconfirm
