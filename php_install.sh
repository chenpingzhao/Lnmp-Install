#!/bin/bash

export PATH=/usr/bin/:/bin:/sbin

dir="/usr/local/src"
[ -d $dir ] || mkdir -p $dir

#############################################################################

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
	"php-5.6.13.tar.gz  http://cn2.php.net/distributions/php-5.6.13.tar.gz"
)

function build() 
{
	echo "build"
	make >/dev/null 2>&1
	[ $? -eq 0 ] || exit 1
	
    make install >/dev/null 2>&1
	[ $? -eq 0 ] || exit 1
    make clean >/dev/null 2>&1
	/sbin/ldconfig
	#sleep 5
    echo -e "\033[32mInstall Success!!!\033[0m\n"
	showTips
}

function getfile()
{
	cd $dir
	num=${#files[*]}
	for ((i=0;i<$num;i++))
	do
		file=(${files[$i]})
		filename=${file[0]}
		#[ -e ${file[0]} ] || wget -c ${file[1]}
		[ -e ${filename%.tar.gz*} ] || tar zxf ${file[0]}
	done
}

#getfile
function updateSystem(){
	#yum update -y
	yum install -y \
	gcc  gcc-c++  autoconf  libjpeg  libjpeg-devel  libpng  libpng-devel  freetype  \
	freetype-devel  libxml2  libxml2-devel  zlib  zlib-devel  glibc  glibc-devel  glib2  glib2-devel \
	bzip2  bzip2-devel  ncurses  ncurses-devel  curl  curl-devel  e2fsprogs  e2fsprogs-devel  krb5  \
	krb5-devel  libidn  libidn-devel  openssl  openssl-devel  openldap  openldap-devel  nss_ldap  \
	openldap-clients  openldap-servers  make  bison  cmake  lsof  rsync  vixie-cron  subversion  \
	pcre  pcre-devel  lrzsz  wget  vim-common  vim-enhanced  ntp  sudo  chkconfig  openssh*   \
	gd gd2 gd-devel gd2-devel systemtap-sdt-devel
}
##########################################################################
function installJpeg(){
	cd $dir/jpeg-9
	./configure  --enable-shared --enable-static
	build
}
function installLibpng(){
	cd $dir/libpng-1.6.2/
	./configure
	build
}
function installFreetype(){
	cd $dir/freetype-2.4.12/
	./configure
	build
}
function installLibmcrypt(){
	cd $dir/libmcrypt-2.5.8/
	./configure
	build
	cd libltdl/
	./configure --enable-ltdl-install
	build
}
function installLibtool(){
	cd $dir/libtool-2.4.6
	./configure  --enable-ltdl-install
	build
}
function installMhash(){
	cd $dir/mhash-0.9.9.9/
	./configure
	build
}
function installMcrypt(){
	cd $dir/mcrypt-2.6.8/
	export LDFLAGS="-L/usr/local/lib -L/usr/lib"
	export CFLAGS="-I/usr/local/include -I/usr/include"
	touch malloc.h
	/sbin/ldconfig
	./configure  --with-libmcrypt-prefix=/usr 
	build
}
function installGd2(){
	cd $dir/gd-2.0.33
	./configure
	build
}
function installPhp(){
	cd $dir/php-5.6.13
	export LIBS="-lm -ltermcap -lresolv"
	export DYLD_LIBRARY_PATH="/lib/:/usr/lib/:/usr/local/lib:/lib64/:/usr/lib64/:/usr/local/lib64"
    export LD_LIBRARY_PATH="/lib/:/usr/lib/:/usr/local/lib:/lib64/:/usr/lib64/:/usr/local/lib64"
	make clean && make clean all
	./configure \
	--prefix=/usr/local/php \
	--with-config-file-path=/etc/  \
	--with-config-file-scan-dir=/etc/php.d \
	--with-mysql=/usr/local/mysql \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--with-iconv-dir \
	--with-freetype-dir=/usr/lib  \
	--with-jpeg-dir=/usr/lib  \
	--with-png-dir=/usr/lib \
	--with-zlib \
	--with-libxml-dir=/usr/lib \
	--with-pdo-mysql \
	--with-mcrypt=/usr/lib \
	--with-gd \
	--with-openssl \
	--with-curl \
	--with-mhash \
	--with-xmlrpc \
	--enable-xml \
	--enable-bcmath \
	--enable-shmop \
	--enable-sysvsem \
	--enable-inline-optimization \
	--enable-mbregex \
	--enable-fpm \
	--enable-mbstring \
	--enable-gd-native-ttf \
	--enable-pcntl \
	--enable-sockets \
	--enable-zip \
	--enable-soap \
	--enable-opcache \
	--enable-embed=shared \
	--enable-debug \
	--enable-dtrace \
	--enable-maintainer-zts
	
	[ $? -eq 0 ] || exit 1
	make -j8
	make install
	#ln -s /usr/local/mysql/lib/libmysqlclient.18.dylib /usr/lib/libmysqlclient.18.dylib
}

function writeConfig(){

PATH=$PATH:$HOME/bin:/usr/local/mysql/bin:/usr/local/mysql/lib:/usr/local/php/bin
#source /root/.bash_profile
. ~/.bash_profile

cd $dir/php-5.6.13
cp ./sapi/fpm/init.d.php-fpm  /etc/init.d/php-fpm
chmod 700 /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig --level 345 php-fpm on
sed -i -r 's@(php_fpm_CONF=)\$\{exec_prefix\}@\1@' /etc/init.d/php-fpm 
sed -i -r 's@(php_fpm_PID=)\$\{exec_prefix\}@\1@' /etc/init.d/php-fpm

cat > /etc/php.ini << "EOF"
[PHP]
engine = On
short_open_tag = On
asp_tags = Off
precision = 14
y2k_compliance = On
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 100
allow_call_time_pass_reference = Off
safe_mode = On
safe_mode_gid = On
safe_mode_include_dir =
safe_mode_exec_dir = /data/www/tmp/:/data/www/
safe_mode_allowed_env_vars = PHP_
safe_mode_protected_env_vars = LD_LIBRARY_PATH
open_basedir = /data/www/tmp/:/data/www/
disable_functions = phpinfo,system,passthru,shell_exec,escapeshellarg,escapeshellcmd,proc_close,proc_open,dl,popen,show_source
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 900     
max_input_time = 600
max_input_vars = 2000
memory_limit = 256M
error_reporting = E_COMPILE_ERROR|E_RECOVERABLE_ERROR|E_ERROR|E_CORE_ERROR
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = Off
error_log = /data/logs/error/php_errors.log
variables_order = "GPCS"
request_order = "GP"
register_globals = Off
register_long_arrays = Off
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 16M
magic_quotes_gpc = Off
magic_quotes_runtime = Off
magic_quotes_sybase = Off
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_tmp_dir = /data/www/tmp
upload_max_filesize = 16M
max_file_uploads = 20
allow_url_fopen = ON
allow_url_include = Off
default_socket_timeout = 60
[Date]
date.timezone = UTC
[filter]
[iconv]
[intl]
[sqlite]
[sqlite3]
[Pcre]
[Pdo]
[Phar]
[Syslog]
define_syslog_variables  = Off
[mail function]
SMTP = localhost
smtp_port = 25
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[MySQL]
mysql.allow_persistent = On
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
[MySQLi]
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[OCI8]
[PostgresSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.save_path = "/data/www/tmp"
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly = 
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.bug_compat_42 = Off
session.bug_compat_warn = Off
session.referer_check =
session.entropy_length = 0
session.entropy_file =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatability_mode = Off
mssql.secure_connection = Off
[Assertion]
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
[sysvshm]
EOF

cat >/etc/php-fpm.conf << "EOF"
include=/etc/php-fpm.d/*.conf
[global]
pid = /var/run/php-fpm.pid
error_log = /data/logs/error/php-fpm-error.log
log_level = notice
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
daemonize = yes
EOF

[ -d /etc/php-fpm.d ] || mkdir /etc/php-fpm.d -p

cat > /etc/php-fpm.d/www-a.conf << "EOF"
; Start a new pool named 'www'.
[www-a]
listen = /dev/shm/php-fpm.socket

listen.owner = www
listen.group = webgrp
listen.mode = 0666

user = www
group = webgrp

pm = static
pm.max_children = 20
pm.start_servers = 8
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 256000

pm.status_path = /status

request_terminate_timeout = 15s
;request_slowlog_timeout = 10s
;slowlog = /data/logs/error/php-fpm-slow.log

rlimit_files = 65536 
rlimit_core = 0
 
catch_workers_output = yes
 
;security.limit_extensions = .php .php3 .php4 .php5

;env[HOSTNAME] = $HOSTNAME
;env[PATH] = /usr/local/bin:/usr/bin:/bin
;env[TMP] = /tmp
;env[TMPDIR] = /tmp
;env[TEMP] = /tmp

;php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f www@my.domain.com
;php_flag[display_errors] = on
php_admin_value[error_log] = /data/logs/error/php-fpm-www-error.log
php_admin_flag[log_errors] = on
;php_admin_value[memory_limit] = 32M

EOF

service php-fpm restart

}

function showTips(){
echo -e "\e[1;32mUse stdin as a command argument ! \e[0m \e[1;33m";

cat << EOF 
+---------------------------------------------------------------------------+
|    1、getfile                                                             |
|    2、updateSystem                                                        |
|    3、installJpeg                                                         |
|    4、installLibpng                                                       |
|    5、installFreetype                                                     |
|    6、installLibmcrypt                                                    |
|    7、installLibtool                                                      |
|    8、installMhash                                                        |
|    9、installMcrypt                                                       |
|    10、installGd2                                                         |
|    11、installPhp                                                         |
|    12、writeConfig                                                        |
|    13、all                                                                | 
+---------------------------------------------------------------------------+
EOF

echo -e "\e[0m";

}

Usage="getfile|updateSystem|installJpeg|installLibpng|installFreetype|installLibmcrypt|installLibtool|installMhash|installMcrypt|installGd2|installPhp|writeConfig"
typeset -l input

showTips
echo -e "\e[42;31m--- please input your select! ---\e[0m\n";

while read input; do


case "$input" in
	h)
	showTips
		;;
	exit)
		exit 0
		;;
	$input)
		[[ $input =~ ^[0-9]+$ ]] && [[ "$input" -gt 0 && "$input" -lt 14 ]] && {
		
			$(echo $Usage | awk -F '|' "BEGIN{ input="$input" } {print \$$input}")

		}  || { echo -e "\n\e[1;31m--- sorry,input error! ---\e[0m\n";  continue;  }
		;;
     *)
		showTips
     #echo $"Usage: $0 {getfile|updateSystem|installJpeg|installLibpng|installFreetype|installLibmcrypt|installLibtool|installMhash|installMcrypt|installGd2|installPhp|writeConfig}"

 esac

done  < "${1:-/dev/stdin}"
