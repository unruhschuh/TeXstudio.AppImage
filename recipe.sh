#!/bin/bash

# Halt on errors
set -e

######################################################
# install packages
######################################################
sudo yum -y install fontconfig fontconfig-devel openjpeg openjpeg-devel cmake
sudo yum -y install epel-release
sudo yum -y install qt5-qtbase-devel qt5-qtbase-gui qt5-qtscript-devel qt5-qtscript qt5-qtsvg-devel qt5-qtsvg qt5-qttools-devel qt5-qttools qt5-qttools-static
sudo ln -s /usr/bin/moc-qt5 /usr/bin/moc
sudo yum -y install cmake binutils fuse glibc-devel glib2-devel fuse-devel gcc zlib-devel # AppImageKit dependencies


# Need a newer gcc, getting it from Developer Toolset 2
sudo wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
sudo yum -y install devtoolset-2-gcc devtoolset-2-gcc-c++ devtoolset-2-binutils
source /opt/rh/devtoolset-2/enable

######################################################
# build libraries from source
######################################################
# Change directory to build. Everything happens in build.
mkdir build
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
tar xfv poppler-0.40.0.tar
cd poppler-0.40.0
./configure && make && sudo make install
cp ../poppler-qt5.pc /tmp
export PKG_CONFIG_PATH=/tmp
cd ..

######################################################
# Build TeXstudio
######################################################
wget http://sourceforge.net/projects/texstudio/files/texstudio/TeXstudio%202.10.8/texstudio-2.10.8.tar.gz
tar xfvz texstudio-2.10.8.tar.gz
cd texstudio2.10.8
qmake-qt5 texstudio.pro
make
INSTALL_ROOT=/tmp/texstudio
cd ..

######################################################
# Build AppImageKit
######################################################
if [ ! -d AppImageKit ] ; then
  git clone https://github.com/probonopd/AppImageKit.git
fi
cd AppImageKit/
cmake .
make clean
make
cd ..

######################################################
# create AppDir
######################################################
APP=TeXstudio
APP_DIR=$APP.AppDir
APP_IMAGE=$APP.AppImage
TXS_SOURCE_DIR=build/texstudio2.10.8

mkdir $APP_DIR
mv /tmp/texstudio/usr $APP_DIR/
mkdir $APP_DIR/usr/lib
mkdir $APP_DIR/usr/lib/qt5
mkdir $APP_DIR/usr/bin/platforms

cp AppImageKit/AppRun $APP_DIR/
cp start_texstudio.sh $APP_DIR/usr/bin

cp $APP_DIR/usr/share/icons/hicolor/scalable/apps/texstudio.svg $APP_DIR/
cp $APP_DIR/usr/share/applications/texstudio.desktop $APP_DIR/
sed -i -e 's/Exec=texstudio %F/Exec=start_texstudio.sh %F/g' -e 's/Icon=texstudio/Icon=texstudio.svg/g' $APP_DIR/texstudio.desktop

cp -R /usr/lib64/qt5/plugins $APP_DIR/usr/lib/qt5/
cp $APP_DIR/usr/lib/qt5/plugins/platforms/libqxcb.so $APP_DIR/usr/bin/platforms/

set +e
ldd $APP_DIR/usr/lib/qt5/plugins/platforms/libqxcb.so | grep "=>" | awk '{print $3}' | xargs -I '{}' cp -v '{}' $APP_DIR/usr/lib
ldd $APP_DIR/usr/bin/* | grep "=>" | awk '{print $3}' | xargs -I '{}' cp -v '{}' $APP_DIR/usr/lib
find $APP_DIR/usr/lib -name "*.so*" | xargs ldd | grep "=>" | awk '{print $3}' | xargs -I '{}' cp -v '{}' $APP_DIR/usr/lib
set -e

cp /usr/local/lib/libjpeg.so.8 $APP_DIR/usr/lib

cp $(ldconfig -p | grep libEGL.so.1 | cut -d ">" -f 2 | xargs) $APP_DIR/usr/lib/ # Otherwise F23 cannot load the Qt platform plugin "xcb"

cp /usr/local/lib/libpoppler-qt5.so.1 $APP_DIR/usr/lib
#cp /usr/local/lib/libpoppler.so.58 $APP_DIR/usr/lib

# Delete potentially dangerous libraries
rm -f $APP_DIR/usr/lib/libstdc* $APP_DIR/usr/lib/libgobject* $APP_DIR/usr/lib/libc.so.* || true

# The following are assumed to be part of the base system
rm -f $APP_DIR/usr/lib/libgtk-x11-2.0.so.0 || true # this prevents Gtk-WARNINGS about missing themes
 rm Ipe.AppDir/usr/lib/libdbus-1.so.3 || true # this prevents '/var/lib/dbus/machine-id' error on fedora 22/23 live cd
rm -f $APP_DIR/usr/lib/libcom_err.so.2 || true
rm -f $APP_DIR/usr/lib/libcrypt.so.1 || true
rm -f $APP_DIR/usr/lib/libdl.so.2 || true
rm -f $APP_DIR/usr/lib/libexpat.so.1 || true
rm -f $APP_DIR/usr/lib/libfontconfig.so.1 || true
rm -f $APP_DIR/usr/lib/libgcc_s.so.1 || true
rm -f $APP_DIR/usr/lib/libglib-2.0.so.0 || true
rm -f $APP_DIR/usr/lib/libgpg-error.so.0 || true
rm -f $APP_DIR/usr/lib/libgssapi_krb5.so.2 || true
rm -f $APP_DIR/usr/lib/libgssapi.so.3 || true
rm -f $APP_DIR/usr/lib/libhcrypto.so.4 || true
rm -f $APP_DIR/usr/lib/libheimbase.so.1 || true
rm -f $APP_DIR/usr/lib/libheimntlm.so.0 || true
rm -f $APP_DIR/usr/lib/libhx509.so.5 || true
rm -f $APP_DIR/usr/lib/libICE.so.6 || true
rm -f $APP_DIR/usr/lib/libidn.so.11 || true
rm -f $APP_DIR/usr/lib/libk5crypto.so.3 || true
rm -f $APP_DIR/usr/lib/libkeyutils.so.1 || true
rm -f $APP_DIR/usr/lib/libkrb5.so.26 || true
rm -f $APP_DIR/usr/lib/libkrb5.so.3 || true
rm -f $APP_DIR/usr/lib/libkrb5support.so.0 || true
# rm -f $APP_DIR/usr/lib/liblber-2.4.so.2 || true # needed for debian wheezy
# rm -f $APP_DIR/usr/lib/libldap_r-2.4.so.2 || true # needed for debian wheezy
rm -f $APP_DIR/usr/lib/libm.so.6 || true
rm -f $APP_DIR/usr/lib/libp11-kit.so.0 || true
rm -f $APP_DIR/usr/lib/libpcre.so.3 || true
rm -f $APP_DIR/usr/lib/libpthread.so.0 || true
rm -f $APP_DIR/usr/lib/libresolv.so.2 || true
rm -f $APP_DIR/usr/lib/libroken.so.18 || true
rm -f $APP_DIR/usr/lib/librt.so.1 || true
rm -f $APP_DIR/usr/lib/libsasl2.so.2 || true
rm -f $APP_DIR/usr/lib/libSM.so.6 || true
rm -f $APP_DIR/usr/lib/libusb-1.0.so.0 || true
rm -f $APP_DIR/usr/lib/libuuid.so.1 || true
rm -f $APP_DIR/usr/lib/libwind.so.0 || true
rm -f $APP_DIR/usr/lib/libz.so.1 || true

# patch hardcoded '/usr/lib' in binaries away
find $APP_DIR/usr/ -type f -exec sed -i -e 's|/usr/lib|././/lib|g' {} \;

######################################################
# Create AppImage
######################################################
# Convert the AppDir into an AppImage
#AppImageKit/AppImageAssistant.AppDir/package ./$APP_DIR/ ./$APP_IMAGE

