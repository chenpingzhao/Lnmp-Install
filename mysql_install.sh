#!/bin/bash

export PATH=/usr/bin/:/bin:/sbin

dir="/usr/local/src"
[ -d $dir ] || mkdir -p $dir

#############################################################################

files=(
"ncurses-5.9.tar.gz ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz"
"cmake-3.2.1.tar.gz http://www.cmake.org/files/v3.2/cmake-3.2.1.tar.gz"
"bison-3.0.1.tar.gz http://ftp.gnu.org/gnu/bison/bison-3.0.1.tar.gz"
"mysql-5.6.25.tar.gz http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.25.tar.gz"
)

function getfile()
{
    cd $dir
    num=${#files[*]}
    for ((i=0;i<$num;i++))
    do
        file=(${files[$i]})
        filename=${file[0]}
        [ -f ${file[0]} ] || wget -c ${file[1]}
        [ -e ${filename%.tar.gz*} ] || tar zxf ${file[0]}
    done
}

function init(){
yum install -y make  gcc gcc-c++ autoconf automake
} 

function createDir(){
[ -d /data/mysql ] || mkdir /data/mysql -p
[ -d /data/logs/mysql ] || mkdir /data/logs/mysql -p
[ -d /data/logs/mysql/binarylog ] || mkdir /data/logs/mysql/binarylog -p

chown -R mysql:mysql /data/logs/mysql
chown -R mysql:mysql /data/mysql
}

function createUser(){
grep mysql /etc/group &>1 /dev/null || /usr/sbin/groupadd mysql
id mysql >& /dev/null || /usr/sbin/useradd -g webgrp mysql -M  -s /sbin/nologin
ulimit -SHn 65535
}

#############################################################################

function build(){
echo "build"
make >/dev/null 2>&1
[ $? -eq 0 ] || exit 1

make install >/dev/null 2>&1
[ $? -eq 0 ] || exit 1
make clean >/dev/null 2>&1
/sbin/ldconfig
#sleep 5
echo -e "\033[32mInstall Success!!!\033[0m\n"
}

function installNcurses(){
cd $dir/ncurses-5.9
./configure
build
}

function installCmake(){
cd $dir/cmake-3.2.1
./bootstrap
build
}

function installBison(){
cd $dir/bison-3.0.1
./configure
build
}

function installMysql(){
cd $dir/mysql-5.6.25
cmake \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
    -DMYSQL_DATADIR=/data/mysql \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_MEMORY_STORAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DSYSCONFDIR=/etc/ \
    -DMYSQL_UNIX_ADDR=/data/mysql/mysqld.sock \
    -DMYSQL_TCP_PORT=3306  \
    -DENABLED_LOCAL_INFILE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_SSL=yes \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_DEBUG=on \
    -DWITH_READLINE=on
build

cp /usr/local/mysql/support-files/my-default.cnf /etc/my.cnf
cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld
chkconfig --add mysqld
chkconfig --level 345 mysqld on
}

function installMysqldb(){
rm -rf /data/mysql/*
pkill mysqld
/usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql --pid-file=/data/mysql/mysql.pid --tmpdir=/tmp --explicit_defaults_for_timestamp

cat > /etc/my.cnf << "EOF"
[client]
port = 3306
socket = /data/mysql/mysql.sock

[mysqld_safe]
log_error=/data/logs/mysql/mysql_error.log


[mysqld]
log_error=/data/logs/mysql/mysql_error.log
port = 3306
socket = /data/mysql/mysql.sock
datadir = /data/mysql
character-set-server=utf8
collation-server=utf8_general_ci

ft_min_word_len = 1
back_log = 600
open_files_limit    = 10240
max_connections = 1024
max_connect_errors = 6000
default-storage-engine = Innodb
skip-name-resolve
skip-external-locking
key_buffer_size = 256M
max_allowed_packet = 256M
table_open_cache = 512
table_open_cache = 256
sort_buffer_size = 4M
read_buffer_size = 4M
join_buffer_size = 8M
read_rnd_buffer_size = 4M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size= 16M
wait_timeout = 1200

#Slow query Log

log-output=FILE
general_log=ON
general_log_file=/data/logs/mysql/general_log.log

long_query_time = 2 
slow-query-log = on
slow-query-log-file = /data/logs/mysql/slow_query.log
log-queries-not-using-indexes

binlog_format=row
max_binlog_size=1024M
log_bin=/data/logs/mysql/binarylog/mysql_bin
expire_logs_days=0
binlog_cache_size = 2M
max_binlog_cache_size = 4M

# defaults to 1 if master-host is not set
server-id = 1

innodb_data_home_dir = /data/mysql
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = /data/mysql
innodb_buffer_pool_size = 1024M
innodb_additional_mem_pool_size = 20M
innodb_log_file_size = 64M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
#safe-updates

[myisamchk]
key_buffer_size = 128M
sort_buffer_size = 128M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES 

EOF

service mysqld start

}


#############################################################################

case "$1" in
    init)
        $1  
        ;;  
    getfile)
        $1  
        ;;  
    createDir)
        $1  
        ;;  
    createUser)
        $1  
        ;;  
    installNcurses)
        $1  
        ;;  
    installCmake)
        $1  
        ;;  
    installBison)
        $1  
        ;;  
    installMysql)
        $1  
        ;;  
    installMysqldb)
        $1
        ;;

    *)  
        echo $"Usage: $0 {init|getfile|createDir|createUser|installNcurses|installCmake|installBison|installMysql|installMysqldb}"
        exit 1
esac

