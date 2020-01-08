#!/usr/bin/env bash

# Start GUI on Ubuntu
echo "Start GUI by default?"
while true ; do
    read -p "[y]/n " yn
    case ${yn} in
        [Nn]* ) break;;
        * ) systemctl set-default graphical.target; break;;
    esac
done
systemctl isolate graphical.target
