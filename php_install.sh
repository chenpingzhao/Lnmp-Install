#!/bin/bash

shopt -s -o nounset
export PATH=/usr/bin/:/bin

#############################################################################
cat << EOF
+---------------------------------------------------------------------------+
|  INSTALL PHP for the CentOS 6.                                            |
+---------------------------------------------------------------------------+
EOF

dir="/usr/local/src"

files=(
	"jpegsrc.v9.tar.gz http://www.ijg.org/files/jpegsrc.v9.tar.gz"
	"libpng-1.6.2.tar.gz http://prdownloads.sourceforge.net/libpng/libpng-1.6.2.tar.gz"
	"freetype-2.4.12.tar.gz http://download.savannah.gnu.orgeleases/freetype/freetype-2.4.12.tar.gz"
	"libmcrypt-2.5.8.tar.gz http://downloads.sourceforge.net/mcrypt/libmcrypt-2.5.8.tar.gz"
	"libtool-2.4.6.tar.gz http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz"
	"libmcrypt-2.5.8.tar.gz http://downloads.sourceforge.net/mcrypt/libmcrypt-2.5.8.tar.gz"
	"mcrypt-2.6.8.tar.gz http://downloads.sourceforge.net/mcrypt/mcrypt-2.6.8.tar.gz"
	"php-5.4.45.tar.gz http://cn2.php.net/distributions/php-5.4.45.tar.gz"
)

function build() 
{
	make && make install && make clean
    echo -e "\033[32m Install Success!!!\033[0m\n"
}

function getfile()
{
	[ -d $dir ] || mkdir -p $dir
	cd $dir
	
	num=${#files[*]}
	for ((i=0;i<$num;i++))
	do
		file=(${files[$i]})
		[ -e ${file[0]} ] || wget -c ${file[1]}
		#tar zxf $file[0]
	done
}

getfile
exit
##########################################################################

#install jpeg
echo "install jpeg."

cd /usr/local/src/jpeg-9
./configure  --enable-shared --enable-static --prefix=/usr/local
make && make install

build
##########################################################################
#install libpng
echo "install libpng."

cd /usr/local/src/libpng-1.6.2/
./configure --prefix=/usr/local
build

##########################################################################
#install freetype
echo "install freetype."
cd /usr/local/src/freetype-2.4.12/
./configure --prefix=/usr/local
build

##########################################################################
#install libmcrypt
echo "install libmcrypt."

cd /usr/local/src/libmcrypt-2.5.8/
./configure --prefix=/usr/local
make && make install
/sbin/ldconfig
cd libltdl/
./configure --enable-ltdl-install
build

##########################################################################
#install libtool
echo "install libtool."

cd /usr/local/src/libtool-2.4.6
./configure --prefix=/usr/local --enable-ltdl-install
build

##########################################################################
#install mhash
echo "install mhash."

cd /usr/local/src/mhash-0.9.9.9/
./configure --prefix=/usr/local
build

##########################################################################
#install mcrypt
echo "install mcrypt."

cd /usr/local/src/mcrypt-2.6.8/
export LDFLAGS="-L/usr/local/lib -L/usr/lib"
export CFLAGS="-I/usr/local/include -I/usr/include"
touch malloc.h
/sbin/ldconfig
./configure --prefix=/usr/local --with-libmcrypt-prefix=/usr/local
build

##########################################################################
#install php
echo "install php."

cd /usr/local/src/php-5.4.45
./configure \
--prefix=/usr/local/php \
--with-config-file-path=/etc/  \
--with-config-file-scan-dir=/etc/php.d \
--with-mysql=/usr/local/mysql \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-iconv-dir \
--with-freetype-dir=/usr/local/lib  \
--with-jpeg-dir=/usr/local/lib  \
--with-png-dir=/usr/local/lib \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-mcrypt=/usr/local/lib \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--enable-opcache \
--with-pdo-mysql \
--enable-embed=shared \
--enable-debug \
--enable-dtrace \
--enable-maintainer-zts

build
cp php.ini-development /etc/php.ini
ln -s /usr/local/mysql/lib/libmysqlclient.18.dylib /usr/lib/libmysqlclient.18.dylib
mv /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
ln -s /usr/local/php/bin/*  /usr/bin

