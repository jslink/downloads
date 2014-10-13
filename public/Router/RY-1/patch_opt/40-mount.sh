#!/bin/sh
# Copyright (C) 2009-2012 OpenWrt.org
# Copyright (C) 2010 Vertical Communications
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

. /lib/functions/block.sh

blkdev=`dirname $DEVPATH`
dev_head=`basename $blkdev`
if [ "$dev_head" != "block" ]; then

    device=`basename $DEVPATH`
    mountpoint=`sed -ne "s|^[^ ]*/$device ||; T; s/ .*//p" /proc/self/mounts`

    case "$ACTION" in
	add)

		local from_fstab
		local anon_mount
		local anon_swap
		local anon_fsck
		local mds_mount_target
		local mds_mount_device
		local mds_mount_fstype
		local sds_swap_device
		local use_device
		local do_fsck=0
		local fsck_type
		local device_type_tmp
		local ext_type
		local autoswap_from_fstab
		local automount_from_fstab

	    mount_dev_section_cb() {
    		mds_mount_target="$2"
			mds_mount_device="$3"
			mds_mount_fstype="$4"
			mds_mount_enabled="$6"
	    }

	    swap_dev_section_cb() { 
			sds_swap_device="$2"
			return 0
	    }

		config_get_automount
		automount_from_fstab="$from_fstab"
		[ "$automount_from_fstab" -eq 1 ] && {
			config_get_mount_section_by_device "/dev/$device"
			use_device="$mds_mount_device"
			[ "$mds_mount_enabled" -eq 1 ] && {
				if [ -n "$mds_mount_target" ]; then
					grep -q "/dev/$device" /proc/swaps || grep -q "/dev/$device" /proc/mounts || {
						( mkdir -p "$mds_mount_target" && mount "$mds_mount_target" ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
					}
				else
					logger -t 'fstab' "Mount enabled for $mds_mount_device but it doesn't have a defined mountpoint (target)"
				fi
			}
		}

		[ -z "$use_device" ] && {
			config_get_autoswap
			autoswap_from_fstab="$from_fstab"
		
			[ "$autoswap_from_fstab" -eq 1 ] && {
				config_get_swap_section_by_device "/dev/$device"
				use_device="$sds_swap_device"
			}
		}
		
		grep -q "/dev/$device" /proc/swaps || grep -q "/dev/$device" /proc/mounts || {
			[ "$anon_mount" -eq 1 -a -z "$use_device" ] && {
				case "$device" in
					mtdblock*) ;;
					*)
						[ `which fdisk` ] && {
							device_type_tmp="`blkid|grep -w $device |awk -F "TYPE" '{print $2}'`"
							[ -n "$device_type_tmp" ] && {
								case "$device_type_tmp" in
									*ntfs*)
										[ -n "`which ntfs-3g`" ] && {
											( mkdir -p /mnt/$device && ntfs-3g -o noatime,big_writes,async,nls=utf8 /dev/$device /mnt/$device ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
										}
									;;
									*exfat*)
										[ -n "`lsmod|grep exfat`" ] && {
											( mkdir -p /mnt/$device && mount -t exfat /dev/$device /mnt/$device ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
										}
									;;
									*vfat*)
										( mkdir -p /mnt/$device && mount -t vfat -o iocharset=utf8,rw,umask=0000,dmask=0000,fmask=0000 /dev/$device /mnt/$device ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
									;;
									*ext*)
										ext_type="`echo $device_type_tmp|awk -F '"' '{print $2}'`"
										[ -n "$ext_type" ] && {
											( mkdir -p /mnt/$device && mount -t $ext_type /dev/$device /mnt/$device ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
										}
									;;
									*swap*)
										( mkswap -f /dev/$device && swapon /dev/$device ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
									;;
									*)
										logger -t 'fstab' "unknown device type $device_type_tmp"
									;;
									*hfs*)
										( mkdir -p /mnt/$device && mount -o force -t hfsplus /dev/$device /mnt/$device ) 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
									;;
								esac
								[ -f /dev/$device/swapfile ] && {
									mkswap /dev/$device/swapfile
									swapon /dev/$device/swapfile
								}
							}
						}
						[ -f /tmp/mount.sh ] || {
							[ -f /etc/mount.sh ] && cp /etc/mount.sh /tmp/mount.sh
						}
						[ -s /tmp/mount.sh ] && {
							/bin/sh /tmp/mount.sh $device $dev_head 1>/dev/null 2>&1
						}
					;;
				esac
			}
		}
		reset_dev_section_cb
		;;
	remove)
		[ -f /dev/$device/swapfile ] && {
			swapoff /dev/$device/swapfile
		}
		[ -f /tmp/umount.sh ] || {
			[ -f /etc/umount.sh ] && cp /etc/umount.sh /tmp/umount.sh
		}
		[ -s /tmp/umount.sh ] && {
			/bin/sh /tmp/umount.sh $device $dev_head 1>/dev/null 2>&1
		}
		umount /dev/$device 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
		umount /mnt/$device 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
		[ -d /mnt/$device ] && rmdir /mnt/$device 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
		[ -n "$mountpoint" ] && umount $mountpoint 2>&1 | tee /proc/self/fd/2 | logger -t 'fstab'
		;;
    esac	

fi

