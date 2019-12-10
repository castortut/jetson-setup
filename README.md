
###########################
### RUN ON YOUR MACHINE ###
###########################

### Prepairing your machine to run ARM binaries

## Install qemu-static
dnf install qemu-user-static
systemctl restart systemd-binfmt


###  Mount the rootfs

## Find the partition offset

parted sd-blob-b01.img
> unit B
> p

 - Take note of the start position of the rootfs

## Mount the root filesystem and some necessary virtual filesystems, then chroot

mount -o loop,offset=12582912 sd-blob-b01.img /mnt
cd /mnt

# The following might be needed, at least if you get "/bin/bash: no such file or directory" on chroot
cp /usr/bin/qemu-aarch64-static usr/bin/

mount -t proc proc proc/
mount -t sysfs sysfs sys/
mount -t devtmpfs devtmpfs dev/

chroot ./

##############################
### RUN ON THE JETSON ROOTFS #
##############################

### Automated install

## Remove some unnecessary firstboot-wizard plugins. We don't want to manually accept the nv license every time
## and we create the user manually
mkdir /usr/lib/ubiquity/plugins.disabled
mv /usr/lib/ubiquity/plugins/nvlicense.py /usr/lib/ubiquity/plugins/ubi-usersetup.py /usr/lib/ubiquity/plugins.disabled/

# Hack because I can't figure out how to preconfigure/skip the language selection screen
sed -i 's/return localechooser_script, questions, environ/return localechooser_script, [], environ/' /usr/lib/ubiquity/plugins/ubi-language.py

## Prepare debconf for automated config:
cat <<EOF >/preseed.cfg
d-i auto-install/enable boolean true
d-i localechooser/languagelist string English
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select fi
d-i keyboard-configuration/layoutcode string fi
d-i keyboard-configuration/variantcode string
d-i time/zone string Europe/Helsinki
EOF

## Load the preseed answers and add --automatic to nv-oem-config-firstboot

mkdir /etc/systemd/system/nv-oem-config-gui.service.d
cat <<EOF >//etc/systemd/system/nv-oem-config-gui.service.d/auto.conf
[Service]
# ExecStart is additive, so clear first
ExecStart=
ExecStart=/bin/sh -ec '\
    debconf-set-selections /preseed.cfg; \
    exec nv-oem-config-firstboot --automatic'
EOF

### Software

## Set a temporary DNS server, will get overwritten when full system is running
echo nameserver 8.8.8.8 > /etc/resolv.conf

## Set a locale to avoid some warnings. Also make it permanent
export LC_ALL=en_DK.UTF-8 LANG=en_DK.UTF-8
update-locale LANG=en_DK.UTF-8

## TODO: Fix the Nvidia repo which at this point has a <SOC> placeholder

apt update

## Restore some missing things like man-pages
unminimize

## Upgrade packages and install some tools and libraries we'll need later on

apt upgrade
apt install python3-pip git libjpeg-dev libhdf5-dev libfreetype6-dev htop rsync screen
pip3 install virtualenvwrapper


### Jetson user

## Create the user and set a basic password

useradd -m -G sudo,gdm,video -s /bin/bash jetson
echo "jetson:jetson" | chpasswd

### The rest we run as the jetson user:

su - jetson

## set up the virtualenv

echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> .bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> .bashrc
source .bashrc

mkvirtualenv donkey1
echo "workon donkey1" >> .bashrc
source .bashrc

## Install donkeycar

cd
git clone https://github.com/castortut/donkeycar.git
cd donkeycar
git checkout master

## It is recommended to find a set of wheels (prebuilt binaries) for the libraries with binary extensions
## and install them before running the following

pip install -e .[nano]
pip install matplotlib

## Download mycar
cd
git clone https://github.com/castortut/donkey_mycar.git mycar; 
cd mycar

#######################
### POST FIRST-BOOT ###
#######################

## This requires more space than the 12GB image has left so do it after copying to an SD card and resizing the filesystem:

pip install --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v42 tensorflow-gpu==1.14.0+nv19.9