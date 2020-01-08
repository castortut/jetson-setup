#!/usr/bin/env bash

ENV_NAME=donkey
RS_VER=v2.31.0

# Get virtual env name and realsense version from arguments
while getopts e:v: option
do
case "${option}"
in
e) ENV_NAME=${OPTARG};;
v) RS_VER=${OPTARG};;
esac
done

sudo apt update && sudo apt -y upgrade

# For now, librealsense must be built to get pyrealsense2.
# In the future, if pip install pyrealsense2 works, try getting librealsense from the repo below:

# Install librealsense from Intel Librealsense Debian repo
# sudo apt-key adv --keyserver keys.gnupg.net --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || sudo apt-key adv --keyserver \ hkp://keyserver.ubuntu.com:80 --recv-key 
# sudo add-apt-repository "deb http://realsense-hw-public.s3.amazonaws.com/Debian/apt-repo bionic main" -u
# sudo apt install -y apt-utils
# sudo apt install -y librealsense2-utils librealsense2-dev
# pip install pyrealsense2



# Install dependencies for librealsense
sudo apt install -y libssl-dev libusb-1.0-0-dev pkg-config
sudo apt install -y build-essential cmake cmake-curses-gui
sudo apt install -y libgtk-3-dev libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
# Checkout librealsense from git
cd
git clone https://github.com/IntelRealSense/librealsense.git
cd librealsense
git checkout $RS_VER
# Build with cmake, especially with flags -DBUILD_PYTHON_BINDINGS=bool:true and
# -DPYTHON_EXECUTABLE=~/.virtualenvs/$ENV_NAME/bin/python
mkdir build 
cd build
export CUDACXX=/usr/local/cuda-10.0/bin/nvcc
export PATH=${PATH}:/usr/local/cuda/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64
/usr/bin/cmake ../ -D BUILD_EXAMPLES=true \
                   -D FORCE_LIBUVC=true \
                   -D BUILD_WITH_CUDA=true \
                   -D CMAKE_BUILD_TYPE=release \
                   -D BUILD_PYTHON_BINDINGS=bool:true \
                   -D PYTHON_EXECUTABLE=~/.virtualenvs/$ENV_NAME/bin/python ..

# Build with all four cores.
echo "Building librealsense... this usually takes 1-1.5 hours."
NUM_CPU=$(nproc)
time make -j"$NUM_CPU"
sudo make install
# Add to path if not yet added
if  grep -Fxq 'export PYTHONPATH=$PYTHONPATH:/usr/local/lib' ~/.bashrc ; then
    echo "PYTHONPATH already exists in .bashrc file"
else
   echo 'export PYTHONPATH=$PYTHONPATH:/usr/local/lib' >> ~/.bashrc 
   echo "PYTHONPATH added to ~/.bashrc. Pyhon wrapper is now available for importing pyrealsense2"
fi

# Copy over the udev rules so that camera can be run from user space
sudo cp ~/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && udevadm trigger


echo "The librealsense library is installed in /usr/local/lib"
echo "The librealsense header files are in /usr/local/include"
echo "The librealsense demos and tools are located in /usr/local/bin"
