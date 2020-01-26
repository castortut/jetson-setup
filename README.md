# RUN ON YOUR MACHINE

## Prepairing your machine to run ARM binaries

### Install qemu-static
```
dnf install qemu-user-static
systemctl restart systemd-binfmt
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

# The following might be needed, at least if you get "/bin/bash: no such file or directory" on chroot
cp /usr/bin/qemu-aarch64-static usr/bin/

mount -t proc proc proc/
mount -t sysfs sysfs sys/
mount -t devtmpfs devtmpfs dev/

chroot ./
```

# RUN ON THE JETSON ROOTFS

## Automated install


### Set a temporary DNS server, will get overwritten when full system is running
```
echo nameserver 8.8.8.8 > /etc/resolv.conf
```
### TODO: Run ansible

### Upgrade packages and install some tools and libraries we'll need later on
```
apt upgrade
apt install python3-pip git libjpeg-dev libhdf5-dev libfreetype6-dev htop rsync screen
pip3 install virtualenvwrapper
```

## Jetson user

### Create the user and set a basic password
```
useradd -m -G sudo,gdm,video -s /bin/bash jetson
echo "jetson:jetson" | chpasswd
```
### The rest we run as the jetson user:
```
su - jetson
```

### set up the virtualenv
```
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> .bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> .bashrc
source .bashrc

mkvirtualenv donkey1
echo "workon donkey1" >> .bashrc
source .bashrc
```

### Install donkeycar
```
cd
git clone https://github.com/castortut/donkeycar.git
cd donkeycar
git checkout master
```

### It is recommended to find a set of wheels (prebuilt binaries) for the libraries with binary extensions and install them before running the following
```
pip install -e .[nano]
pip install matplotlib
```

## Download mycar
```
cd
git clone https://github.com/castortut/donkey_mycar.git mycar; 
cd mycar
```

# POST FIRST-BOOT #

## This requires more space than the 12GB image has left so do it after copying to an SD card and resizing the filesystem:

```
pip install --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v42 tensorflow-gpu==1.14.0+nv19.9
```
