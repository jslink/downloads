#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/rom/bin:/rom/sbin:/rom/usr/bin:/rom/usr/sbin
mlog=/tmp/mount.log
device="$1"
dev_head="$2"
echo "+mount $dev_head:$device" >>$mlog
dev_usb_state_file="/tmp/usbstate"
USB_MNT_TMP="/tmp/usbdir"
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
		uci set samba.@sambashare[-1].create_mask=0755
		uci set samba.@sambashare[-1].dir_mask=0755
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
delete_samba_share() {
	samba_config search /mnt/$1
	samba_config del $del_samba_index
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
	sleep 1
}
start_config() {
	if [ -f /usr/local/xcloud/bin/searchSharePath.sh ]; then
		/usr/local/xcloud/bin/searchSharePath.sh $1 /mnt/$1
	fi
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
ctl_plugin() {
	Path="/opt/app/appinstalled/"
	AutoRun_Udisk="2"
	AllFile=`ls $Path`
	for EachFile in ${AllFile}
	do
		OneFilePath=`printf "%s%s" "$Path" "$EachFile"`
		AutoRun=`cat ${OneFilePath} | grep "plugin_Autorun" |awk -F ":" '{print $2}' | awk -F " " '{print $1}'`
		if [ "$AutoRun" = "$AutoRun_Udisk" ]; then
			AppInstallPath=`cat ${OneFilePath} | grep "plugin_IntallPath"  |awk -F ":" '{print $2}' | awk -F " " '{print $1}'`
			AppShellCtl=`printf "%sappshell %s" "$AppInstallPath" "$1"`
			$AppShellCtl
			sleep 2
		fi
	done
}

###########################################################
[ -z "`echo $dev_head | grep mtd`"] && {
	device_type="`blkid|grep -w /dev/$device|awk -F "TYPE" '{print $2}'|awk -F '"' '{print $2}'`"
	[ -n "`echo $device_type|grep ex`" ] && {
		[ -n "`mount|grep -w /mnt/$device`" ] || {
			mkdir -p /mnt/$device
			ret='success'
			mount -t $device_type /dev/$device /mnt/$device
			[ $? -eq 0 ]||ret='failed'
			echo "+mount /dev/$device /mnt/$device $ret" >>$mlog
		}
		[ -z "`mount|grep /opt`" ] && {
			if [ -z "`mount|grep -E '/dev/mmc.*/overlay|/dev/sd.*/overlay'`" ]; then
				if [ -n "`mount|grep /dev/$device\ on\ /mnt/$device\ type`" ]; then
					[ -d "/mnt/$device/opt" ]||mkdir -p /mnt/$device/opt
					mkdir -p /opt
					mount /mnt/$device/opt /opt
					echo "+mount /opt /mnt/$device/opt" >>$mlog
					ctl_plugin start 1>/dev/null 2>&1 &
				fi
			else
				[ -d /opt ]||mkdir -p /opt
				ret='success'
				mount /overlay/opt /opt
				[ $? -eq 0 ]||ret='failed'
				echo "+mount /overlay/opt /opt $ret" >>$mlog
				ctl_plugin start 1>/dev/null 2>&1 &
			fi
		}
		start_config $device
		echo "/dev/$device /mnt/$device" > $USB_MNT_TMP
		echo "+xcloud device $device" >>$mlog
		mountdir="`mount|grep /dev/$device\ on\ /mnt/$device\ type|awk '{print $3}'|head -n 1`"
		[ -n "$mountdir" ] && {
			stop_samba
			samba_config add $device $mountdir 1>/dev/null 2>&1
			echo "+samba add $device $mountdir" >>$mlog
			start_samba
		}
		echo '--------------------------' >>$mlog
	}
	rm -rf $dev_usb_state_file
	rm -rf /tmp/usbdev
	rm -rf /tmp/usbmounted
	/bin/sh /usr/local/localshell/usb-iso-check 1>/dev/null 2>&1
}
