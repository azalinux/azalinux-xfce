#!/bin/bash -x
set -e
set -u

pacman -S --noconfirm reflector
reflector --latest 200 -c Australia -p http -p https --save /etc/pacman.d/mirrorlist
