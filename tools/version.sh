#!/bin/sh -e
#

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

git_bin=$(which git)

omap_bootloader () {
	unset test_var
	test_var=$(dd if=${drive} count=6 skip=393248 bs=1 2>/dev/null || true)
	if [ "x${test_var}" = "xU-Boot" ] ; then
		uboot=$(dd if=${drive} count=32 skip=393248 bs=1 2>/dev/null || true)
		uboot=$(echo ${uboot} | awk '{print $2}')
		echo "bootloader:[${label}]:[${drive}]:[U-Boot ${uboot}]"
	fi
}

if [ -f ${git_bin} ] ; then
	if [ -d /opt/scripts/ ] ; then
		old_dir="`pwd`"
		cd /opt/scripts/ || true
		echo "git:/opt/scripts/:[`${git_bin} rev-parse HEAD`]"
		cd "${old_dir}" || true
	fi
fi

if [ -f /sys/bus/i2c/devices/0-0050/eeprom ] ; then
	board_eeprom=$(hexdump -e '8/1 "%c"' /sys/bus/i2c/devices/0-0050/eeprom -n 28 | cut -b 5-28 || true)
	echo "eeprom:[${board_eeprom}]"
fi

if [ -f /etc/dogtag ] ; then
	echo "dogtag:[`cat /etc/dogtag`]"
fi

#if [ -f /bin/lsblk ] ; then
#	lsblk | sed 's/^/partition_table:[/' | sed 's/$/]/'
#fi

if [ -b /dev/mmcblk0 ] ; then
	label="microSD-(push-button)"
	drive=/dev/mmcblk0
	omap_bootloader
fi

if [ -b /dev/mmcblk1 ] ; then
	label="eMMC-(default)"
	drive=/dev/mmcblk1
	omap_bootloader
fi

echo "kernel:[`uname -r`]"

if [ -f /usr/bin/nodejs ] ; then
	echo "nodejs:[`/usr/bin/nodejs --version`]"
fi

if [ -f /boot/uEnv.txt ] ; then
	unset test_var
	test_var=$(cat /boot/uEnv.txt | grep -v '#' | grep dtb | grep -v dtbo || true)
	if [ "x${test_var}" != "x" ] ; then
		echo "device-tree-override:[$test_var]"
	fi
fi

if [ -f /boot/uEnv.txt ] ; then
	unset test_var
	test_var=$(cat /boot/uEnv.txt | grep -v '#' | grep enable_uboot_overlays=1 || true)
	if [ "x${test_var}" != "x" ] ; then
		cat /boot/uEnv.txt | grep uboot_ | grep -v '#' | sed 's/^/uboot_overlay_options:[/' | sed 's/$/]/'
	fi
fi
#
