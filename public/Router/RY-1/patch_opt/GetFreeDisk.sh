#!/bin/sh
#set -x

Parameter_num=$#
Parameter_one=$1
G_Parameter_all=$*

if [ $# -ne 1 ];then
	echo "GetFreeDisk - Parameter Err."
	exit 1
elif [ "$1" == "rom" ];then	
	local size_room=""
	local size_dev=""
	local size_mtdblock7=""
	size_room=`/bin/df -k | grep "/rom" |awk -F " " '{print $4}'|awk -F " " '{print $1}'`
	size_dev=`/bin/df -k |grep "tmpfs"| grep "/dev" |awk -F " " '{print $4}'|awk -F " " '{print $1}'`
	#size_mtdblock7=`/bin/df -k | grep "/dev/mtdblock7" |awk -F " " '{print $4}'|awk -F " " '{print $1}'`
	#上面是原来的方法，如果挂了overlay就无效了
	size_mtdblock7=`/bin/df -k | grep "/overlay" |awk -F " " '{print $4}'|head -n 1|awk -F " " '{print $1}'`
	if [ "${size_room}" == "" ];then
		echo "ERROR"
		exit 1
	elif [ "${size_dev}" == "" ];then
		echo "ERROR"
		exit 1
	elif [ "${size_mtdblock7}" == "" ];then
		echo "ERROR"
		exit 1		
	fi
	
	size_room=`printf "%d" ${size_room}`
	size_dev=`printf "%d" ${size_dev}`
	size_mtdblock7=`printf "%d" ${size_mtdblock7}`
	RomSize=`expr ${size_room} + ${size_dev} + ${size_mtdblock7}`
	RomSize="${RomSize}K"
	echo ${RomSize}
	exit 0
elif [ "$1" == "usb" ];then
	local size_usb=""
	local usb_name=""
	mount|grep -E '/dev/sd.*|/dev/mmcblk.*'|awk '{print $1}'|sort -u|while read usb_name; do
		[ -n "$usb_name" ] && {
			size_usb=`/bin/df -h|grep $usb_name.*/ |awk '{print $4}'|tail -n 1`
			[ -n "$size_usb" ] && {
				echo -n "$temp`basename $usb_name`,$size_usb||||"
			}
		}
	done
	exit 0
elif [ "$1" == "usbiso" ];then
	if [ ! -d "/opt" ];then
		echo "ERROR"
		exit 2
	else
		usbiso_size=`/bin/df -h|grep /opt|awk '{print $4}'|tail -n 1`
		echo "$usbiso_size"
		exit 0	
	fi
else
	echo "Error:Parameter Error!"
	exit 1		
fi
