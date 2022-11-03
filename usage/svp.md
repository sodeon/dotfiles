# Latest      : https://www.svp-team.com/wiki/SVP:Linux
# Ubuntu 20.04: https://ls4every1.blogspot.com/2020/07/smooth-video-project-4-installing_18.html
#               https://www.youtube.com/watch?v=ABrO2kdXCWE

sudo apt update
sudo apt install g++
sudo apt update -y
# sudo apt install -y beignet-opencl-icd
sudo apt install mediainfo
sudo apt install libqt5concurrent5 libqt5svg5 libqt5qml5
# sudo add-apt-repository ppa:rvm/smplayer
# sudo apt update
# sudo apt install smplayer smplayer-themes smplayer-skins
sudo apt install g++ make autoconf automake libtool pkg-config nasm git # nasm used for mpv build
# git clone https://github.com/sekrit-twc/zimg.git
# cd zimg 
# ./autogen.sh
# ./configure
# make -j4
# sudo make install
# cd ..
sudo apt install libzimg-dev cython3
# git clone --branch R50 https://github.com/vapoursynth/vapoursynth.git
git clone --branch R50 https://github.com/vapoursynth/vapoursynth.git
cd vapoursynth
./autogen.sh
./configure
make -j4
sudo make install
cd ..
sudo ldconfig
sudo ln -s /usr/local/lib/python3.8/site-packages/vapoursynth.so /usr/lib/python3.8/lib-dynload/vapoursynth.so
sudo apt install libssl-dev libfribidi-dev libluajit-5.1-dev libx264-dev xorg-dev libegl1-mesa-dev libfreetype-dev libfontconfig-dev
sudo apt install libasound2-dev libpulse-dev
sudo apt install python-is-python3
# sudo apt install python-minimal
git clone https://github.com/mpv-player/mpv-build.git
cd mpv-build
echo --enable-libx264 >> ffmpeg_options
echo --enable-vapoursynth >> mpv_options
echo --enable-libmpv-shared >> mpv_options
./rebuild -j4
sudo ./install
cd ..
# Final binary: /usr/local/lib/mpv


            mpvsocket
SVPManager ----------> mpv
