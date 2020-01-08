#!/usr/bin/env bash

# Turn off swap
sudo swapoff /var/swapfile
# Take automount off
sudo sed --in-place "/swapfile swap swap defaults 0 0/d" /etc/fstab
# Reboot
# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
while true ; do
    echo "Ready to reboot? SWAP is not unallocated before rebooting!"
    read -p "Y/N " yn
    case ${yn} in
        [Yy]* ) sudo reboot now ;;
        [Nn]* ) exit ;;
        * ) echo "Please answer y or n." ;;
    esac
done
