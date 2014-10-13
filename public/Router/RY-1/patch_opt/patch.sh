#!/bin/sh
#set -x

err_exit(){
	echo $1
	exit 1
}
down_file(){
	rm -f $1
	wget -q $baseurl/$1
	if [ -f $1 ];then
		if [ "`ls -l $1|awk '{print $5}'`" = "0" ];then
			echo "check $1 error"
			[ $dest -eq 0 ]||sed -i "s#dest root /#dest root $destdir#g" /etc/opkg.conf
			exit 1
		else
			rm -f $2
			mv $1 $2
			chmod +x $2
		fi
	else
		echo "download $1 error"
		[ $dest -eq 0 ]||sed -i "s#dest root /#dest root $destdir#g" /etc/opkg.conf
		exit 1
	fi
}


[ -f /etc/openwrt_version ]||err_exit 'unkown version'
[ -f /etc/hotplug.d/block/40-mount ]||err_exit 'no support'
[ -f /usr/local/app/xipk ]||err_exit 'no support'
[ -f /usr/local/app/GetFreeDisk ]||err_exit 'no support'
[ -f /usr/local/localshell/usb-iso-check ]||err_exit 'no support'
[ -f /usr/local/localshell/usb-mount ]||err_exit 'no support'

[ "`cat /etc/openwrt_version`" = "1.6.1.5" ]||err_exit "OS Version: `cat /etc/openwrt_version` No Support"

cd /tmp
dest=0
destdir="`cat /etc/opkg.conf|grep -vE '^$|^#.*$'|grep -E 'dest.+root.+'|awk '{print $3}'`"
if [ "$destdir" != "/" ]; then
	dest=1
	sed -ri 's/^\ *dest.+root.+$/dest\ root\ \//g' /etc/opkg.conf
fi
rm -f 1s_mmc_for_ry1.6.1.5.ipk
wget http://downloads.jslink.org/public/Router/RY-1/1s_mmc_for_ry1.6.1.5.ipk
opkg install 1s_mmc_for_ry1.6.1.5.ipk
rm -f 1s_mmc_for_ry1.6.1.5.ipk

baseurl='http://downloads.jslink.org/public/Router/RY-1/patch_opt'

down_file '40-mount.sh' '/etc/hotplug.d/block/40-mount'
down_file 'xipk.sh' '/usr/local/app/xipk'
down_file 'GetFreeDisk.sh' '/usr/local/app/GetFreeDisk'
down_file 'usb-iso-check.sh' '/usr/local/localshell/usb-iso-check'
down_file 'usb-mount.sh' '/usr/local/localshell/usb-mount'
down_file 'Monitor.sh' '/usr/local/localshell/Monitor.sh'
down_file 'mount.sh' '/etc/mount.sh'
down_file 'umount.sh' '/etc/umount.sh'
echo ''
echo 'patch success !!!'
echo ''
[ $dest -eq 0 ]||sed -i "s#dest root /#dest root $destdir#g" /etc/opkg.conf
exit 0


