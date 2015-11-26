#!/bin/bash

shopt -s -o nounset
export PATH=/usr/bin/:/bin

#############################################################################
cat << EOF
+---------------------------------------------------------------------------+
|  INSTALL NGINX for the CentOS 6.                                          |
+---------------------------------------------------------------------------+
EOF


dir="/usr/local/src"
[ -d $dir ] || mkdir -p $dir

##########################################################################

function createDir(){
    [ -d /data/logs/error ] || mkdir /data/logs/error -p
    [ -d /data/logs/access ] || mkdir /data/logs/access -p
    [ -d /data/www/tmp/cache ] || mkdir /data/www/tmp/cache -p
 
}
 
function createUser(){
    grep webgrp /etc/group &>1 /dev/null || /usr/sbin/groupadd webgrp
    id www >& /dev/null || /usr/sbin/useradd -g webgrp www  -s /sbin/nologin
    ulimit -SHn 65535
}
 
function downFile(){
    cd $dir
    [ -d pcre-8.37 ] || wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz && tar zxf pcre-8.37.tar.gz
    [ -d nginx-sticky-module-1.1 ] || wget https://nginx-sticky-module.googlecode.com/files/nginx-sticky-module-1.1.tar.gz && tar zxf nginx-sticky-module-1.1.tar.gz
    [ -d tengine-1.5.0 ] || wget http://tengine.taobao.org/download/tengine-1.5.0.tar.gz && tar zxf tengine-1.5.0.tar.gz
    [ -d ngx_cache_purge-2.3 ] || wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz && tar zxf ngx_cache_purge-2.3.tar.gz
    [ -d GeoIP-1.4.8 ] || wget http://geolite.maxmind.com/download/geoip/api/c/GeoIP.tar.gz && tar zxf GeoIP.tar.gz
    [ -d gperftools-2.1 ]|| wget -c ftp://ftp.tw.freebsd.org/pub/ports/distfiles/gperftools-2.1.tar.gz && tar zxf gperftools-2.1.tar.gz
    [ -d libunwind-1.1 ] || wget  -c http://download.savannah.gnu.org/releases/libunwind/libunwind-1.1.tar.gz >libunwind-1.1.tar.gz && tar zxf libunwind-1.1.tar.gz
}
function tarxFile(){
    cd $dir
    [ -d pcre-8.37 ] ||   tar zxf pcre-8.37.tar.gz
    [ -d nginx-sticky-module-1.1 ] ||  tar zxf nginx-sticky-module-1.1.tar.gz
    [ -d tengine-1.5.0 ] || tar zxf tengine-1.5.0.tar.gz
    [ -d ngx_cache_purge-2.3 ] ||  tar zxf ngx_cache_purge-2.3.tar.gz
    [ -d GeoIP-1.4.8 ] ||  tar zxf GeoIP.tar.gz
    [ -d gperftools-2.1 ]|| tar zxf gperftools-2.1.tar.gz
    [ -d libunwind-1.1 ] ||  tar zxf libunwind-1.1.tar.gz
	
}

 
function installLibunwind(){
    cd $dir/libunwind-1.1
    CFLAGS=-fPIC ./configure  --enable-shared
    make CFLAGS=-fPIC
    make CFLAGS=-fPIC install
 
}
 
function installGeoIP(){
    cd $dir/GeoIP-1.4.8
    ./configure
    make && make install
    echo '/usr/local/lib' > /etc/ld.so.conf.d/geoip.conf
    /sbin/ldconfig
}
 
function installPcre(){
    cd $dir/pcre-8.37
    ./configure --prefix=/usr/local/
    make && make install
}
 
function installGperftools(){
    cd $dir/gperftools-2.1
    ./configure  --enable-shared   --enable-frame-pointers
    make && make install
    /sbin/ldconfig
}
 
function installTengine(){
    cd $dir/tengine-1.5.0
 
    sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
    sed -i 's@#define TENGINE_VERSION    "1.5.0"@#define TENGINE_VERSION    "1.5.0"@' src/core/nginx.h
    sed -i 's@#define TENGINE            "Tengine"@#define TENGINE            "Apache"@' src/core/nginx.h
 
./configure \
--prefix=/usr/local/nginx \
--error-log-path=/data/logs/error/error.log \
--http-log-path=/data/logs/access/access.log \
--pid-path=/var/run/nginx/nginx.pid  \
--lock-path=/var/lock/nginx.lock \
--conf-path=/etc/nginx/nginx.conf \
--sbin-path=/usr/sbin/nginx \
--user=www \
--group=webgrp \
--with-debug \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_image_filter_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_sysguard_module \
--with-backtrace_module \
--with-http_stub_status_module \
--with-http_upstream_check_module \
--with-google_perftools_module \
--with-http_geoip_module \
--with-pcre=/usr/local/src/pcre-8.37 \
--with-http_image_filter_module \
--add-module=/usr/local/src/ngx_cache_purge-2.3  \
--add-module=/usr/local/src/nginx-sticky-module-1.1
 
make && make install
 
mkdir /etc/nginx/vhosts
 
}
 
function writeConfigure(){
 
[ -d /etc/nginx/vhosts/ ] || mkdir /etc/nginx/vhosts/ -p
 
cat > /etc/nginx/nginx.conf << "EOF"
 
user  www  webgrp;
 
worker_processes  4;
worker_cpu_affinity  0001 0010 0100 1000;
worker_rlimit_nofile    65536;
 
pid     /var/run/nginx.pid;
#error_log  /data/logs/error/nginx_error.log  info;
google_perftools_profiles /data/www/tmp/tcmalloc;
 
events
{
    use epoll;
    worker_connections  65536;
}
 
http
{
    include mime.types;
    default_type    application/octet-stream;
    charset  utf-8;
 
    server_names_hash_bucket_size 128;
    client_header_buffer_size 4k;
    large_client_header_buffers 4 32k;
    client_max_body_size 32m;
     
    open_file_cache max=65536 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 1;
     
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 60;
    tcp_nodelay on;
    server_tokens off;
    port_in_redirect off;
             
    fastcgi_connect_timeout 600;
    fastcgi_send_timeout 600;
    fastcgi_read_timeout 600;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 128k;
    fastcgi_temp_path /dev/shm/nginx_tmp;
    fastcgi_intercept_errors on;   
    #fastcgi_cache_path /data/www/tmp/_fcgi_cache levels=2:2 keys_zone=ngx_fcgi_cache:512m inactive=1d max_size=10g;
 
    #open gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 4;
    gzip_proxied any;
    gzip_types  text/plain application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;   
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";
 
   #GeoIp
   #geoip_country /etc/nginx/geoip/GeoIP.dat;
   #geoip_city    /etc/nginx/geoip/GeoLiteCity.dat;
 
    #Proxy
    proxy_connect_timeout   600;
    proxy_read_timeout  600;
    proxy_send_timeout  600;
    proxy_buffer_size   16k;
    proxy_buffers   4   32k;
    proxy_busy_buffers_size 64k;
    proxy_temp_file_write_size  64k;
    proxy_cache_path /data/www/tmp/cache levels=1:2 keys_zone=Z:100m inactive=7d max_size=30g;
     
    #Limit
    limit_req_zone $binary_remote_addr  zone=xxx:10m rate=5r/s;
    limit_req_zone $binary_remote_addr  zone=qps1:1m rate=1r/s;
 
     
    #Log format
     
    log_format  access  '$remote_addr - $remote_user [$time_local] "$request" '
          '$status $body_bytes_sent "$http_referer" '
          '"$http_user_agent"  $http_x_forwarded_for  $request_body'
          'upstream_response_time $upstream_response_time request_time $request_time';
     
    #502_next
        upstream php_fpm_sock{
            server unix:/dev/shm/php-fpm.socket;
            server unix:/dev/shm/php-fpm-b.socket;
            server unix:/dev/shm/php-fpm-c.socket;
       }
 
        fastcgi_next_upstream error timeout invalid_header http_503  http_500;
     
    #cros
    add_header Access-Control-Allow-Origin http://bbs.erongtu.com; 
    #add_header Access-Control-Allow-Headers X-Requested-With; 
    #add_header Access-Control-Allow-Methods GET,POST,OPTIONS;
    #add_header X-Cache-CFC "$upstream_cache_status - $upstream_response_time";
 
    server
    {
        listen 80 default;
        server_name _;
        return 444;
    }
     
    include vhosts/*.conf;
}
     
EOF
 
 
cat > /etc/nginx/vhosts/example.conf  << "EOF"
 
server {
    listen 80;
    server_name www.example.com example.com;
    root /data/www/www.example.com/;
    index  index.php index.html index.htm;
    access_log /data/logs/access/www.example.com_access.log access;
    error_log /data/logs/error/www.example.com_error.log crit;
 
    location @fobidden{
        include fastcgi_params;
        fastcgi_pass unix:php_fpm_sock;
        fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;
        allow 124.160.24.242;
        deny all;
    }
     
    location /nginx_status {
            stub_status on;
            access_log   off;
            allow 42.121.124.115;
        allow 124.160.24.242;
            deny all;
        }
 
    location = /status {
        try_files $uri $uri/ @fobidden;
    }
     
    if ($host = example.com ) {
        return 301 $scheme://www.example.com$request_uri;
    }
 
    location ~ /bbs/ {
        if ($host = www.example.com ) {
            rewrite ^/bbs/(.*)$ $scheme://bbs.example.com/$1 permanent;
            break;
        }
    }
 
 
    location = /application/ {
        return 302 /application/uploads/other/404-3.jpg;
    }
 
    location / {
        try_files $uri $uri/ /application.php?s=$uri&$args;
    }
     
    location ~* \.php($|/){
        set $script     $uri;
        set $path_info  "";
        if ($uri ~ "^(.+?\.php)(/.+)$") {
            set $script     $1;
            set $path_info  $2;
        }
        fastcgi_pass unix:php_fpm_sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$script;
        fastcgi_param  SCRIPT_NAME $script;
        fastcgi_param  PATH_INFO $path_info;
        include fastcgi.conf;
        include fastcgi_params;
 
        #fastcgi_cache ngx_fcgi_cache;
        #fastcgi_cache_valid 200 302 1h;
        #fastcgi_cache_valid 301 1d;
        #fastcgi_cache_valid any 1m;
        #fastcgi_cache_min_uses 1;
        #fastcgi_cache_use_stale error timeout invalid_header http_500;
        #fastcgi_cache_key $scheme://$host$request_uri;
 
    }
 
    location ~ /rbc/ {
        rewrite /rbc/(.*)/index.html$ /rbc/index.php?$1 last;
        rewrite /rbc/(.*)/index(\d+).html$ /rbc/index.php?$1&page=$2 last;
        rewrite /rbc/(.*)/a(\d+)\.html$ /rbc/index.php?$1/$2 last;
        rewrite /rbc/u/(\d+)/rbc/(.*)$ /rbc/index.php?u&$1&$2 last;
        rewrite /rbc/u/(\d+)/rbc/(.*)/$ /rbc/index.php?u&$1&$2 last;
        rewrite /rbc/u/(\d+)$ /rbc/index.php?u&$1 last;
        rewrite /rbc/u/(\d+)/$ /rbc/index.php?u&$1 last;
        rewrite /rbc/(.*)/index.html\?(.*) /rbc/index.php?$1&$2 last;
        rewrite /rbc/(.*)/index(\d+).html\?(.*) /rbc/index.php?$1&$2 last;
        rewrite /rbc/index.action(.*) /rbc/index.php$1 last;
 
    }
 
    location ~* \.(ico|jpe?g|gif|png|bmp|swf|flv)(\?[0-9]+)?$ {
         
        if ( !-e $request_filename ){  
            rewrite ^/application/(portal.*)$   /bbs/data/attachment/$1 last;
            rewrite ^/info/data/attachment(.*)$ /bbs/data/attachment/$1 last;
            rewrite ^/admin/data/attachment(.*)$ /bbs/data/attachment/$1 last;
            rewrite ^/bbs/data/attachment/(.*)\.thumb\.jpg$ /application/$1 last;
            rewrite ^/bbs/application/(.*)$ /application/$1 last;
        }
        expires 30d;
        log_not_found off;
        access_log off;
    }
 
    location ~* \.(js|css)$ {
        expires 7d;
        log_not_found off;
        access_log off;
    }  
 
    location = /(favicon.ico|roboots.txt) {
        access_log off;
        log_not_found off;
    }
 
    location ~* \.(htacess|svn|tar.gz|tar|zip|sql) {
        return 404;
    }
 
     
    #location ~* \.(gif|jpg|png|swf|flv)$ {
    #   valid_referers none blocked www.example.com example.com
    #   if ($invalid_referer) {
    #       return 404;
    #   }
    #} 
 
    error_page 404 500 502 /Common/tpl/404.html;
}
 
 
EOF
}
 
function writeInit(){
 
cat > /etc/init.d/nginx << "EOF"
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /var/run/nginx.pid
 
# Source function library.
. /etc/rc.d/init.d/functions
 
# Source networking configuration.
. /etc/sysconfig/network
 
# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0
 
nginx="/usr/sbin/nginx"
prog=$(basename $nginx)
 
NGINX_CONF_FILE="/etc/nginx/nginx.conf"
 
[ -f /etc/sysconfig/nginx ] && . /etc/sysconfig/nginx
 
lockfile=/var/lock/subsys/nginx
 
start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}
 
stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -TERM
    retval=$?
    if [ $retval -eq 0 ]; then
        if [ "$CONSOLETYPE" != "serial" ]; then
           echo -en "\\033[16G"
        fi
        while rh_status_q
        do
            sleep 1
            echo -n $"."
        done
        rm -f $lockfile
    fi
    echo
    return $retval
}
 
restart() {
    configtest || return $?
    stop
    start
}
 
reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
    sleep 1
    RETVAL=$?
    echo
}
 
configtest() {
  $nginx -t -c $NGINX_CONF_FILE
}
 
rh_status() {
    status $prog
}
 
rh_status_q() {
    rh_status >/dev/null 2>&1
}
 
# Upgrade the binary with no downtime.
upgrade() {
    local pidfile="/var/run/${prog}.pid"
    local oldbin_pidfile="${pidfile}.oldbin"
 
    configtest || return $?
    echo -n $"Staring new master $prog: "
    killproc $nginx -USR2
    sleep 1
    retval=$?
    echo
    if [[ -f ${oldbin_pidfile} && -f ${pidfile} ]];  then
        echo -n $"Graceful shutdown of old $prog: "
        killproc -p ${oldbin_pidfile} -TERM
        sleep 1
        retval=$?
        echo
        return 0
    else
        echo $"Something bad happened, manual intervention required, maybe restart?"
        return 1
    fi
}
 
case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    force-reload|upgrade)
        rh_status_q || exit 7
        upgrade
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    status|status_q)
        rh_$1
        ;;
    condrestart|try-restart)
        rh_status_q || exit 7
        restart
        ;;
    *)
        echo $"Usage: $0 {start|stop|reload|configtest|status|force-reload|upgrade|restart}"
        exit 2
esac
EOF
 
    chmod 755 /etc/init.d/nginx
    chkconfig --add nginx
    chkconfig --level 345 nginx on
    service nginx start
}
function all(){
    createDir
    createUser
    installGeoIP
    installGperftools
    installPcre
    installTengine
    writeConfigure
    writeInit
}
 
 
case "$1" in
     createDir)
         createDir
         ;;
   
     createUser)
         createUser
         ;;

     downFile)
         downFile
         ;;
     tarxFile)
         tarxFile
         ;;

     installLibunwind)
        installLibunwind
        ;;
     installGeoIP)
         installGeoIP
         ;;
   
     installGperftools)
         installGperftools
         ;;
      installPcre)
         installPcre
     ;;
      installTengine)
         installTengine
     ;;
      writeConfigure)
         writeConfigure
     ;;
         
      writeInit)
         writeInit
     ;;
     *)
         echo $"Usage: $0 {createDir|createUser|downFile|tarxFile|installLibunwind|installGeoIP|installGperftools|installPcre|installTengine|writeConfigure|writeInit}"
         exit 1
   
 esac
