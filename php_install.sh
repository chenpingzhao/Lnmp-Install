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
	"gd-2.0.33.tar.gz http://www.boutell.com/gd/http/gd-2.0.33.tar.gz"
	"php-5.4.45.tar.gz http://cn2.php.net/distributions/php-5.4.45.tar.gz"
)

function build() 
{
	make && make install && make clean
	sleep 5
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
		filename=${file[0]}
		[ -e ${file[0]} ] || wget -c ${file[1]}
		[ -e ${filename%.tar.gz*} ] || tar zxf ${file[0]}
	done
}

getfile
##########################################################################
yum update -y
yum install -y \
gcc  gcc-c++  autoconf  libjpeg  libjpeg-devel  libpng  libpng-devel  freetype  \
freetype-devel  libxml2  libxml2-devel  zlib  zlib-devel  glibc  glibc-devel  glib2  glib2-devel \
bzip2  bzip2-devel  ncurses  ncurses-devel  curl  curl-devel  e2fsprogs  e2fsprogs-devel  krb5  \
krb5-devel  libidn  libidn-devel  openssl  openssl-devel  openldap  openldap-devel  nss_ldap  \
openldap-clients  openldap-servers  make  bison  cmake  lsof  rsync  vixie-cron  subversion  \
pcre  pcre-devel  lrzsz  wget  vim-common  vim-enhanced  ntp  sudo  chkconfig  openssh*   \
gd gd2 gd-devel gd2-devel systemtap-sdt-devel

##########################################################################
#install jpeg
echo "install jpeg."

cd $dir/jpeg-9
./configure  --enable-shared --enable-static --prefix=/usr/local >/dev/null 2>&1
build

##########################################################################
#install libpng
echo "install libpng."

cd $dir/libpng-1.6.2/
./configure --prefix=/usr/local
build

##########################################################################
#install freetype
echo "install freetype."
cd $dir/freetype-2.4.12/
./configure --prefix=/usr/local
build

##########################################################################
#install libmcrypt
echo "install libmcrypt."

cd $dir/libmcrypt-2.5.8/
./configure --prefix=/usr/local
make && make install
/sbin/ldconfig
cd libltdl/
./configure --enable-ltdl-install
build

##########################################################################
#install libtool
echo "install libtool."
cd $dir/libtool-2.4.6
./configure --prefix=/usr/local --enable-ltdl-install
build

##########################################################################
#install mhash
echo "install mhash."

cd $dir/mhash-0.9.9.9/
./configure --prefix=/usr/local
build

##########################################################################
#install mcrypt
echo "install mcrypt."

cd $dir/mcrypt-2.6.8/
export LDFLAGS="-L/usr/local/lib -L/usr/lib"
export CFLAGS="-I/usr/local/include -I/usr/include"
touch malloc.h
/sbin/ldconfig
./configure --prefix=/usr/local --with-libmcrypt-prefix=/usr/local
build

##########################################################################
#install gd2
cd $dir/gd-2.0.33
./configure --prefix=/usr/local/gd2
make && make install

##########################################################################
#install php
echo "install php."

cd $dir/php-5.4.45
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
--with-gd=/usr/local/gd2 \
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
