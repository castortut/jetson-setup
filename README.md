# RUN ON YOUR MACHINE

## Prepairing your machine to run ARM binaries

### Install qemu-static
```
dnf install qemu-user-static
systemctl restart systemd-binfmt
```

## Resize image to fit later installations
```
qemu-img resize sd-blob-b01.img 30G
```

##  Mount the rootfs

### Find the partition offset

```
parted sd-blob-b01.img
> unit B
> p
```

 - Take note of the start position of the rootfs

### Mount the root filesystem and some necessary virtual filesystems, then chroot

```
mount -o loop,offset=12582912 sd-blob-b01.img /mnt
cd /mnt
```
If you resized the image earlier:
After mounting, check with lsblk which loop we mounted on, and resize the filesystem to that loop (X).
```
resize2fs /dev/loopX
```
Mount the rest and chroot.
```
# The following might be needed, at least if you get "/bin/bash: no such file or directory" on chroot
cp /usr/bin/qemu-aarch64-static usr/bin/

mount -t proc proc proc/
mount -t sysfs sysfs sys/
mount -t devtmpfs devtmpfs dev/

chroot ./
```

# RUN ON THE JETSON ROOTFS

## Automated install

### Remove some unnecessary firstboot-wizard plugins. We don't want to manually accept the nv license every time and we create the user manually
```
mkdir /usr/lib/ubiquity/plugins.disabled
mv /usr/lib/ubiquity/plugins/nvlicense.py /usr/lib/ubiquity/plugins/ubi-usersetup.py /usr/lib/ubiquity/plugins.disabled/
```

### Hack because I can't figure out how to preconfigure/skip the language selection screen
```
sed -i 's/return localechooser_script, questions, environ/return localechooser_script, [], environ/' /usr/lib/ubiquity/plugins/ubi-language.py
```

### Prepare debconf for automated config:
```
cat <<EOF >/preseed.cfg
d-i auto-install/enable boolean true
d-i localechooser/languagelist string English
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select fi
d-i keyboard-configuration/layoutcode string fi
d-i keyboard-configuration/variantcode string
d-i time/zone string Europe/Helsinki
EOF
```

### Load the preseed answers and add --automatic to nv-oem-config-firstboot
```
mkdir /etc/systemd/system/nv-oem-config-gui.service.d
cat <<EOF >//etc/systemd/system/nv-oem-config-gui.service.d/auto.conf
[Service]
# ExecStart is additive, so clear first
ExecStart=
ExecStart=/bin/sh -ec '\
    debconf-set-selections /preseed.cfg; \
    exec nv-oem-config-firstboot --automatic'
EOF
```

## Software

### Set a temporary DNS server, will get overwritten when full system is running
```
echo nameserver 8.8.8.8 > /etc/resolv.conf
```

### Set a locale to avoid some warnings. Also make it permanent
```
export LC_ALL=en_DK.UTF-8 LANG=en_DK.UTF-8
update-locale LANG=en_DK.UTF-8
```

TODO: Fix the Nvidia repo which at this point has a <SOC> placeholder

```
apt update
```

### Restore some missing things like man-pages
```
unminimize
```

## Jetson user

### Create the user and set a basic password
```
useradd -m -G sudo,gdm,video -s /bin/bash jetson
echo "jetson:jetson" | chpasswd
```
### Don't require sudo password for jetson user
```
visudo
```
Add this to the end of the opened sudoers file as its own line:

```
jetson ALL=(ALL) NOPASSWD: ALL
```
### The rest we run as the jetson user:
```
su - jetson
```
### Run installation script for OpenCV, librealsense and donkeycar
The script sets up a virtual environment, installs all dependencies and installs
Jetson Nano compatible versions of OpenCV2, librealsense2 and donkeycar.

```
cd scripts
chmod +x donkeyinstalls.sh install_opencv.sh install_librealsense.sh
./donkeyinstalls.sh -e donkey
```

## Write the file to SD card

Find the SD card device (probably /dev/sda1)
```
sudo fdisk -l
```
Unmount the partitions and flash your image to the card
```
sudo umount /dev/sdx*
sudo dd bs=1M if=sd-blob-b01.img of=/dev/sdx*
```
After booting, resize to card size and remove the added sudoers line with visudo