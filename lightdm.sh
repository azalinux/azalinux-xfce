#!/bin/bash

set -e

sudo systemctl enable lightdm.service -f
sudo systemctl set-default graphical.target
