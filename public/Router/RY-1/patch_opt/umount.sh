#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/rom/bin:/rom/sbin:/rom/usr/bin:/rom/usr/sbin
mlog=/tmp/mount.log
device="$1"
dev_head="$2"
echo "-umount $dev_head:$device" >>$mlog
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
	#umount all
	[ -n "`df|grep -w /dev/$device|grep -w /opt`" ] && {
		ctl_plugin stop 1>/dev/null 2>&1
		kill_all /opt 1>/dev/null 2>&1
		kill_all /overlay 1>/dev/null 2>&1
		ret='success'
		umount /opt
		[ $? -eq 0 ]||ret='failed'
		echo "-umount $device:/opt $ret" >>$mlog
		[ -n "`df|grep -w /opt`" ] && {
			umount -ldf /opt
		}
	}
	for mountpoint in `df|grep -w /dev/$device|awk '{print $6}'`; do
		[ -n "$mountpoint" ] && {
			kill_all $mountpoint 1>/dev/null 2>&1
			ret='success'
			umount $mountpoint
			[ $? -eq 0 ]||ret='failed'
			echo -n "-umount $mountpoint $ret " >>$mlog
			rmdir $mountpoint
			[ $? -eq 0 ]||ret='failed'
			echo "rmdir $mountpoint $ret" >>$mlog
			[ ! -b /dev/$device ] || {
				[ -n "`df|grep /dev/$device`" ] && umount -ldf $mountpoint
			}
		}
	done
	[ -z "`mount|grep -w /dev/$device`" ] && {
		rm -rf $USB_MNT_TMP
		#mount to other device
		xcloud_device='clear_xcloud'
		for mountdevicepath in `df|grep -E '/dev/sd.+/mnt/sd.+|/dev/mmcblk.+/.+'|awk '{print $1}'|sort -u -r`; do
			[ -n "$mountdevicepath" ] && {
				[ -b $mountdevicepath ] && {
					[ "$xcloud_device" = "clear_xcloud" ] && {
						xcloud_device="`basename $mountdevicepath`"
					}
					mountpoint="`df|grep -w $mountdevicepath|awk '{print $6}'|head -n 1`"
					[ -n "$mountpoint" ] && echo "/dev/$xcloud_device $mountpoint" > $USB_MNT_TMP
					[ ! -d /opt ] && {
						[ -d $mountpoint/opt ] && {
							mkdir -p /opt
							ret='success'
							mount $mountpoint/opt /opt
							[ $? -eq 0 ] && ( ctl_plugin start 1>/dev/null 2>&1 & ) || ret='failed'
							echo "+remount $mountpoint/opt /opt $ret" >>$mlog
						}
					}
				}
			}
		done
		start_config $xcloud_device
		echo "-xcloud device $xcloud_device" >>$mlog
	}
	stop_samba
	delete_samba_share $device 1>/dev/null 2>&1
	echo "-samba delete $device" >>$mlog
	echo '--------------------------' >>$mlog
	sleep 1
	start_samba
	rm -rf $dev_usb_state_file
	rm -rf /tmp/usbdev
	rm -rf /tmp/usbmounted
	/bin/sh /usr/local/localshell/usb-iso-check 1>/dev/null 2>&1
}
