#!/usr/bin/env bash


ENV_NAME=donkey
OPENCV_VER=4.2.0

# Get virtual env name and realsense version from arguments
while getopts e:v: option
do
case "${option}"
in
e) ENV_NAME=${OPTARG};;
v) OPENCV_VER=${OPTARG};;
esac
done

sudo apt update && sudo apt -y upgrade

# Install dependencies for opencv
sudo apt install -y cmake libjpeg-dev
sudo apt install -y build-essential unzip pkg-config libpng-dev libtiff-dev
sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt install -y libxvidcore-dev libx264-dev
sudo apt install -y libgtk-3-dev libatlas-base-dev gfortran
sudo apt install -y python3-dev

# Create a directory for opencv and download
mkdir -p ~/opencv
cd ~/opencv
wget -O opencv.zip https://github.com/opencv/opencv/archive/$OPENCV_VER.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/$OPENCV_VER.zip
unzip opencv.zip
unzip opencv_contrib.zip
rm opencv.zip opencv_contrib.zip
cd opencv-$OPENCV_VER

# Hack for Eigen library error in OpenCV-4.1.1
if [ "$OPENCV_VER" == "4.1.1" ]; then
    sed -i 's/include <Eigen\/Core>/include <eigen3\/Eigen\/Core>/g' modules/core/include/opencv2/core/private.hpp
fi
mkdir build
cd build

# Configure cmake
cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D OPENCV_EXTRA_MODULES_PATH=~/opencv/opencv_contrib-$OPENCV_VER/modules \
    -D PYTHON_EXECUTABLE=~/.virtualenvs/$ENV_NAME/bin/python3.6 \
    -D WITH_CUDA=ON \
    -D CUDA_ARCH_BIN="5.3,6.2,7.2" \
    -D CUDA_ARCH_PTX="" \
    -D WITH_GSTREAMER=ON \
    -D WITH_LIBV4L=ON \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D BUILD_EXAMPLES=OFF ..


# Build with all four cores. Takes up to two hours.
# Close Chromium for optimal performance
echo "Building OpenCV... this usually takes 1-1.5 hours."
NUM_CPU=$(nproc)
time make -j"$NUM_CPU"
sudo make install
sudo ldconfig

if [[ -f  /usr/local/lib/python3.6/dist-packages/cv2/python-3.6/cv2.cpython-36m-aarch64-linux-gnu.so ]]; then
    CV2_LOC=/usr/local/lib/python3.6/dist-packages/cv2/python-3.6
elif [[ -f  /usr/local/lib/python3.6/site-packages/cv2/python-3.6/cv2.cpython-36m-aarch64-linux-gnu.so ]]; then
    CV2_LOC=/usr/local/lib/python3.6/site-packages/cv2/python-3.6
else
    echo "Something went wrong!"
    echo "cv2.cpython-36m-aarch64-linux-gnu.so not found in site-packages or dist-packages."
    exit
fi
# Go to the folder where OpenCV's native library is built
cd "$CV2_LOC"
# Rename
sudo mv cv2.cpython-36m-aarch64-linux-gnu.so cv2.so
# Go to your virtual environments site-packages folder
cd ~/.virtualenvs/$ENV_NAME/lib/python3.6/site-packages/
# Symlink the native library
ln -s "$CV2_LOC"/cv2.so cv2.so

echo "Installed OpenCV. Library is symlinked to virtual environment."
