#!/bin/sh
#set -x

err_exit(){
	echo $1
	exit 1
}

[ "`cat /etc/openwrt_version`" = "1.6.1.5" ]||err_exit "OS Version: `cat /etc/openwrt_version` No Support"

cd /
wget 'http://downloads.jslink.org/public/Router/RY-1/patch.tar.gz'
[ -f /patch.tar.gz ]||err_exit "Download Error"
tar zxvf patch.tar.gz
rm -f patch.tar.gz
echo ''
echo 'patch success !!!'
echo ''
rm -f $0


