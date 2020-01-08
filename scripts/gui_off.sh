#!/usr/bin/env bash

# Stop GUI on Ubuntu
sudo systemctl set-default multi-user.target
echo "GUI is shut down by default after reboot. Reboot now?"
while true ; do
    read -p "y/[n] " yn
    case ${yn} in
        [Yy]* ) break;;
        * ) exit ;;
    esac
done
sudo reboot now
