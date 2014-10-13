#!/bin/sh
 
# Copyright (C) 2009 OpenWrt.org  (C) 2010 OpenWrt.org.cn
#set -x

del_samba_index="0"
samba_config() {
	
 samba_cmd=$1 

 case "$samba_cmd" in
        add)

		samba_dev=$2 
 		samba_path=$3 
		uci add samba samba
		uci set samba.@samba[-1].name=xRouter
		uci set samba.@samba[-1].workgroup=WORKGROUP
		uci set samba.@samba[-1].description=xRouter
		uci set samba.@samba[-1].homes=1
		uci add samba sambashare
		uci set samba.@sambashare[-1].name=xRouter_MNT_$samba_dev
		uci set samba.@sambashare[-1].path=$samba_path
		uci set samba.@sambashare[-1].read_only=no
		uci set samba.@sambashare[-1].guest_ok=yes
		uci set samba.@sambashare[-1].create_mask=0700
		uci set samba.@sambashare[-1].dir_mask=0700
 		uci commit samba 
	 ;;
	del)	
		samba_index=$2 

		uci delete samba.@samba[$samba_index]
		uci delete samba.@sambashare[$samba_index]
		uci commit samba
	 ;;
	search)	
		samba_path=$2 
		del_samba_index=`uci show samba | grep $samba_path | awk -F "]" '{print $1}' | awk -F "[" '{print $2}'`
		
	 ;;

    esac

}

start_SafeAcc() {
	if [ -f /opt/etc/init.d/SafeAcc ]; then
		/opt/etc/init.d/SafeAcc start
	fi
}
stop_SafeAcc() {
	if [ -f /opt/etc/init.d/SafeAcc ]; then
		/opt/etc/init.d/SafeAcc stop
	fi
}

start_config() {
	if [ -f /usr/local/xcloud/bin/searchSharePath.sh ]; then
		/usr/local/xcloud/bin/searchSharePath.sh $1
	fi
	samba_config add $1 /mnt/$1
}
start_samba() {
	if [ -f /etc/init.d/samba ]; then
		/etc/init.d/samba start
	fi
}
stop_samba() {
	if [ -f /etc/init.d/samba ]; then
		/etc/init.d/samba stop
	fi
}

start_thunder() {
	if [ -f /usr/local/thunder/appshell ]; then
		/usr/local/thunder/appshell start 1>/dev/null 2>&1 &
	fi
}
stop_thunder() {
	if [ -f /usr/local/thunder/appshell ]; then
		/usr/local/thunder/appshell stop 1>/dev/null 2>&1 &
	fi
}

start_gpio() {
	capbility=`/usr/local/localshell/getcapability`
	if [ "$capbility" = "RY-02" ]; then
		echo 255 > /sys/class/leds/usb\:blue/brightness
	else
		echo 255 > /sys/class/leds/ry01\:usb/brightness
	fi									
}
stop_gpio() {
		
	check_mount=`mount | grep /dev/sd`

	if [ ! -z "$check_mount" ]; then
		return
	fi

								
	capbility=`/usr/local/localshell/getcapability`
										
	if [ "$capbility" = "RY-02" ]; then
		echo 0 > /sys/class/leds/usb\:blue/brightness
		echo 255 > /sys/class/leds/usb\:yellow/brightness
	fi

}
start_all() {
	start_SafeAcc 1>/dev/null 2>&1
	start_samba  1>/dev/null 2>&1
	ctl_plugin start 1>/dev/null 2>&1
}

delete_samba_share() {
	samba_config search /mnt/$1
	samba_config del $del_samba_index
}
stop_all() {

	stop_SafeAcc 1>/dev/null 2>&1	
	ctl_plugin stop 1>/dev/null 2>&1	
	delete_samba_share $1	
}

kill_all() {
	PIDS=`fuser -m $1`

	 if [ ! -z "$PIDS" ];then
		
		for line in $PIDS
		do
			if [ "$line" -eq "1" ]; then
				break
			fi
  			kill -9 $line 
		done
 	fi
}

Path="/opt/app/appinstalled/"
AutoRun_Udisk="2"

ctl_plugin() {
		AllFile=`ls $Path`
		for EachFile in ${AllFile}
		do
			OneFilePath=`printf "%s%s" "$Path" "$EachFile"`
			AutoRun=`cat ${OneFilePath} | grep "plugin_Autorun" |awk -F ":" '{print $2}' | awk -F " " '{print $1}'`
			 if  [ "$AutoRun" = "$AutoRun_Udisk" ]; then
				AppInstallPath=`cat ${OneFilePath} | grep "plugin_IntallPath"  |awk -F ":" '{print $2}' | awk -F " " '{print $1}'`
				AppShellCtl=`printf "%sappshell %s" "$AppInstallPath" "$1"`
				$AppShellCtl
 
			 fi
		done

}
Parameter_num=$#
USB_MNT_TMP="/tmp/usbdir"
USB_PATITION_TMP="/tmp/usbdev"
dev_usb_state_file="/tmp/usbstate"
MountedDev="/tmp/usbmounted"
local dev_detcet=0
if [ ${Parameter_num} -eq 2 ];then
	device=$2 
	case "$1" in
			remove)
				dev_head="`cat $USB_PATITION_TMP | grep -w $device | awk -F ":" '{print $1}'`"
				if [ -z "$dev_head" ]; then
					echo "Dev Error"
					return
				fi
				stop_all $device
				stop_samba
				stop_thunder
				if [ -f /dev/$device/swapfile ]; then
					swapoff /dev/$device/swapfile
				fi
				[ -f /tmp/umount.sh ] || {
					[ -f /etc/umount.sh ] && cp /etc/umount.sh /tmp/umount.sh
				}
				[ -s /tmp/umount.sh ] && {
					/bin/sh /tmp/umount.sh $device $dev_head 1>/dev/null 2>&1
				}
				sleep 1
				[ -z "`mount|grep -w /dev/$device`" ] && {
					echo "Success"
					start_thunder
				} || {
					echo "Error"
				}
			;;
	esac
else
	echo "Parameter Err"
fi