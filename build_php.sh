#!/bin/bash

if [ $# -ne 1 ]; then
    echo $0: usage: cross_compile_library.sh ARCH 
    echo "example: usage: cross_compile_library.sh [ arm-linux | arm-linux-gnueabihf | arm-linux-gnueabi ]"
    exit 1
fi

export PATH="$1/bin:$PATH"
tool_chain_path=${1%/}


# ======== find architecture ========
item=`ls $tool_chain_path/bin | grep gcc`
IFS=' ' read -ra ADDR <<< "$item"
item="${ADDR[0]}"
ARCH=`echo $item | sed -e 's/-gcc.*//g'`


# ======== setup autoconf 2.13 ========
sudo apt-get install autoconf2.13
if [ ! -f /usr/share/autoconf2.13/acconfig.h ]; then
	sudo ln -s /etc/autoconf2.13/acconfig.h /usr/share/autoconf2.13/acconfig.h
fi
export PHP_AUTOCONF=/usr/bin/autoconf2.13
export PHP_AUTOHEADER=/usr/bin/autoheader2.13
./buildconf --force


## ======== patch for libxml > 2.9.0 ========
#/usr/bin/curl -s https://mail.gnome.org/archives/xml/2012-August/txtbgxGXAvz4N.txt | patch -p0


# ======== download bison 2.4.1 ========
wget https://ftp.gnu.org/gnu/bison/bison-2.4.1.tar.gz
tar -xvf bison-2.4.1.tar.gz
cd bison-2.4.1/
chmod +x configure
mkdir build
./configure
make -j 4
sudo make install
cd ..
rm bison-2.4.1.tar.gz


# ======== php with static build ========
export ARCH=$ARCH
export AR=${ARCH}-ar
export AS=${ARCH}-as
export LD=${ARCH}-ld
export RANLIB=${ARCH}-ranlib
export CC=${ARCH}-gcc
export NM=${ARCH}-nm

make clean
./configure --prefix=$tool_chain_path --target=${ARCH} --host=${ARCH} --enable-static --without-sqlite3 --without-pdo-sqlite --without-pear --enable-simplexml --disable-mbregex --enable-sockets --disable-opcache --enable-libxml --without-zlib --enable-session --enable-json --disable-all --enable-static=yes --enable-shared=no --with-libxml-dir=$tool_chain_path
make
sudo "PATH=$PATH" make install
