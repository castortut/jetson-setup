#!/usr/bin/env bash

# Tested with L4T32.3.1, OpenCV-4.2.0, and librealsense-v2.31.0 

LOG=false
ENV_NAME=donkey

# Get virtual env name and realsense version from arguments
while getopts e:l: option
do
case "${option}"
in
e) ENV_NAME=${OPTARG};;
l) LOG_FILE=${OPTARG}; LOG=true;;
esac
done


echo "TO SPEED INSTALLATION, copy \"wheelhouse\" folder from"
echo "Castor's Google Drive to ~/wheelhouse."
echo ""
echo "If running this script on a Nano with an old build (<32.2.1), "
echo "allocate SWAP. To see amount of SWAP available (and other performance "
echo " info), run 'tegrastats' or 'htop'. If amount of SWAP is 0, "
echo "allocate it by running allocate_swap.sh before proceeding."
echo ""
echo "The default time before 'sudo' rights are asked again is 15 min. "
echo "To increase this to 6 hours, run visudo and add this to the file: "
echo "Defaults:jetson timestamp_timeout=360"
echo ""
echo "Proceed with installation?"
while true ; do
    read -p "y/[n] " yn
    case ${yn} in
        [Yy]* ) break;;
        * ) exit ;;
    esac
done

sudo apt update && sudo apt -y upgrade
sudo apt -y autoremove

# Install comfort tools to make life more comfy
sudo apt install -y nano screen ntp htop rsync nmap

# Write the terminal output to a log file. Might not work correctly?
if "$LOG"; then
    script "$LOG_FILE"
fi

# Install dev tools
sudo apt install -y git cmake libatlas-base-dev gfortran libhdf5-serial-dev hdf5-tools
sudo apt install -y libfreetype6-dev libjpeg-dev apt-utils
sudo apt install -y python3-dev

# Install pip
wget https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py
rm get-pip.py

# Allow caching wheels to .cache/pip
if [ -d ~/.cache/pip ]; then
    sudo chmod -R 777 ~/.cache/pip
fi
if [ -d /root/.cache/pip ]; then
    sudo chmod -R 777 /root/.cache/pip
fi

# Configure virtual environment
sudo pip install virtualenv virtualenvwrapper
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source /usr/local/bin/virtualenvwrapper.sh

echo "# virtualenv and virtualenvwrapper" >> ~/.bashrc
echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
mkvirtualenv $ENV_NAME -p python3
# Open virtualenv automatically
echo "workon $ENV_NAME" >> ~/.bashrc
workon $ENV_NAME

# Install numpy. This will take 10-15 mins if you do not have a wheel
# Pip package version numbers are used so that wheels (prebuilt binaries)
# in wheelhouse are used instead of building wheels of possible newer versions.
pip install --find-links=~/wheelhouse numpy==1.18.0
# Install NVIDIA version of Tensorflow. Check Takes around 40 mins without wheels.
# Note that different Jetpack might need also different Tensorflow wheel!
# Check the url if not using L4T32.3.1.
pip install --find-links=~/wheelhouse --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v43/ tensorflow-gpu==1.15.0+nv19.12
# Install scipy. Takes 50-60 mins without wheel.
pip install --find-links=~/wheelhouse scipy==1.4.0
# Install keras if not yet installed. Takes 30-35 mins without wheel.
pip install --find-links=~/wheelhouse keras

# Install OpenCV. Takes >2 hours and needs >7GB of free space.
# Flags: -e is virtual env name, -v is library version.
cd ~/scripts
./install_opencv.sh -e $ENV_NAME -v 4.2.0

# Install Librealsense with pyrealsense2. Takes > 1 hour.
cd ~/scripts
./install_librealsense.sh -e $ENV_NAME -v v2.31.0

# Install donkeycar and its dependencies. Takes ?? mins without wheels.
cd
git clone https://github.com/castortut/donkeycar.git
cd donkeycar
git checkout master
pip install --find-links=~/wheelhouse pillow==6.2.1
pip install --find-links=~/wheelhouse pandas==0.25.3
pip install --find-links=~/wheelhouse -e .[nano]
pip install --find-links=~/wheelhouse matplotlib==3.1.2
# Make a few directories that are not in git.
# Should be fixed in /parts/datastore.py self.get_tub_list(path) code at some point.
mkdir mycar/logs mycar/models mycar/data
echo "Downloaded and installed donkeycar."
cd

# Make "jetson" user part of the i2c rights group.
sudo usermod -aG i2c jetson
echo "Rights to i2c group given to user. Reboot needed."

# Exit script writing
if "$LOG"; then
    exit
fi

echo "Reboot system to complete."
echo "You can now remove ~/opencv/ and ~/librealsense/ to save space."

# Not needed in Nano L4T versions >=32.2.1
# Remember to unallocate extra SWAP. Checks fstab for the added line, 
# then asks to run the unallocation script. Script reboots system.
if  grep -Fxq '/var/swapfile swap swap defaults 0 0' /etc/fstab ; then
    while true ; do
        echo "Unallocate SWAP now? Extra SWAP wears down SD card!"
        read -p "[y]/n " yn
        case ${yn} in
            [Nn]* ) exit ;;
            * ) ./unallocate_swap.sh;;
        esac
    done
fi
