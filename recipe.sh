#!/bin/bash

sudo yum -y install fontconfig fontconfig-devel openjpeg openjpeg-devel

sudo yum -y install epel-release
sudo yum -y install qt5-qtbase-devel qt5-qtbase-gui qt5-qtscript-devel qt5-qtscript qt5-qtsvg-devel qt5-qtsvg qt5-qttools-devel qt5-qttools qt5-qttools-static
sudo ln -s /usr/bin/moc-qt5 /usr/bin/moc

# Need a newer gcc, getting it from Developer Toolset 2
sudo wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
sudo yum -y install devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils
# /opt/rh/devtoolset-2/root/usr/bin/gcc
# now holds gcc and c++ 4.8.2
#scl enable devtoolset-2
source /opt/rh/devtoolset-2/enable

cd build

# libjpeg
wget http://www.ijg.org/files/jpegsrc.v8d.tar.gz
tar xfvz jpegsrc.v8d.tar.gz
cd jpeg-8d
./configure && make && sudo make install
cd ..

# poppler
wget http://poppler.freedesktop.org/poppler-0.40.0.tar.xz
unxz poppler-0.40.0.tar.xz
cd poppler-0.40.0
./configure && make && sudo make install
cp ../poppler-qt5.pc /tmp
export PKG_CONFIG_PATH=/tmp
cd ..

wget http://sourceforge.net/projects/texstudio/files/texstudio/TeXstudio%202.10.8/texstudio-2.10.8.tar.gz
cd texstudio2.10.8
qmake-qt5 texstudio.pro
make


