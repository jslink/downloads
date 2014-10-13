#!/bin/sh
#set -x
dev_usb_state_file="/tmp/usbstate"
USB_MNT_TMP="/tmp/usbdir"
MountedDev="/tmp/usbmounted"
[ -f $dev_usb_state_file ]||touch $dev_usb_state_file
[ -s $dev_usb_state_file ] || {
	df -h|grep -E '/dev/mmcblk.+|/dev/sd.+'|while read mount_tmp; do
		[ -n "$mount_tmp" ] && {
			device_path="`echo $mount_tmp|awk '{print $1}'`"
			device="`basename $device_path`"
			[ -z "`cat $dev_usb_state_file|grep -w $device`" ] && {
				[ -z "cat $dev_usb_state_file|grep -w $device" ] || {
					mount_size="`echo $mount_tmp|awk '{print $4}'`"
					echo "size: $mount_size"
					mount_path="`echo $mount_tmp|awk '{print $6}'`"
					echo -n "NULL $device $mount_size " >> $dev_usb_state_file
					[ `/bin/df -m|grep -w $device_path|awk '{print $4}'` -lt 2 ] && {
						echo -n "needspace " >> $dev_usb_state_file
					} || {
						[ -n "`mount|grep -w $device_path|grep -E '/opt|/overlay'`" ] && {
							echo -n "ready " >> $dev_usb_state_file
						} || {
							echo -n "null " >> $dev_usb_state_file
						}
					}
					echo "Mounted" >> $dev_usb_state_file
				}
			}	
		}
	done
}



[ -f $USB_MNT_TMP ] || {
	[ -n "`mount|grep /dev/sd`" ] && {
		mount_tmp="`mount|grep /dev/sd|sort|tail -n 1`"
		mount_path="`echo $mount_tmp|awk '{print $3}'`"
		[ -n "$mount_path" ] && {
			mount_device="`echo $mount_tmp|awk '{print $1}'`"
			echo "$mount_device $mount_path" > $USB_MNT_TMP
		} || {
			mount_tmp="`mount|grep -E '/dev/mmc.*/overlay|/dev/sd.*/overlay'`"
			[ -n "$mount_tmp" ] && {
				mount_device="`echo $mount_tmp|awk '{print $1}'`"
				echo "/dev/$mount_device /overlay" > $USB_MNT_TMP
			} || {
				mount_tmp="`mount|grep /dev/mmcblk|sort|tail -n 1`"
				mount_path="`echo $mount_tmp|awk '{print $3}'`"
				[ -n "$mount_tmp" ] && {
					mount_device="`echo $mount_tmp|awk '{print $1}'`"
					echo "$mount_device $mount_path" > $USB_MNT_TMP
				}
			}
		}
	}
}

[ -s /tmp/usbdev -a -s $MountedDev ] || {
rm -rf /tmp/usbdev
rm -rf $MountedDev
touch /tmp/usbdev
fdisk -l|grep Disk\ /dev/|grep -v mtd|awk -F ':' '{print $1}'|awk '{print $2}'|while read device_tmp; do
	device_head="`basename $device_tmp`"
	mount|grep $device_tmp|awk '{print $1}'|while read device_path; do
		device="`basename $device_path`"
		[ -z "`cat /tmp/usbdev|grep $device_head:$device`" ] && {
			echo "$device_head:$device" >> /tmp/usbdev
			echo -n "$device" >> $MountedDev
			#下面是从如意云固件的40-mount拷贝的，真心搞不明白这有什么意思，唉！难道如意云的开发还不如我这入门的水平？
			label="`blkid -o list | grep -w $device | awk '{print $3}'`"
			isNull="`echo $label | grep /$device`"
			if [ -n "$isNull" ]; then
				label="$device"
			fi
			echo -n "//$label" >> $MountedDev
			isVfat="`blkid -s TYPE | grep -w $device | awk '{print $2}' | awk -F '"' '{print $2}' | grep vfat`"
			if [ ! -z "$isVfat" ]; then
				echo "//1" >> $MountedDev
			else
				echo "//0" >> $MountedDev
			fi
			#拷贝结束
		}
	done
done
}

echo "NULL///0"