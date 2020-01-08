#!/usr/bin/env bash

SWAP_SIZE=4G

# Allocates additional swap space at /var/swapfile
sudo fallocate -l $SWAP_SIZE /var/swapfile
# Permissions
sudo chmod 600 /var/swapfile
# Make swap space
sudo mkswap /var/swapfile
# Turn on swap
sudo swapon /var/swapfile
# Automount swap space on reboot
sudo bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'
# Reboot
# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
while true ; do
    echo "Ready to reboot? SWAP is not allocated before rebooting!"
    read -p "Y/N " yn
    case ${yn} in
        [Yy]* ) sudo reboot now ;;
        [Nn]* ) exit ;;
        * ) echo "Please answer y or n." ;;
    esac
done
