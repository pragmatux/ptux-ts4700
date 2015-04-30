#!/bin/sh

echo -n "Checking that filesystem fills storage device... "

disk_size=$(cat /sys/block/mmcblk0/size)
part_size=$(cat /sys/block/mmcblk0/mmcblk0p4/size)
part_start=$(cat /sys/block/mmcblk0/mmcblk0p4/start)
target_size=$(expr $disk_size - $part_start)
fs_blocks=$(dumpe2fs -h /dev/mmcblk0p4 2>/dev/null | awk '/Block count:/ { print $3 }')
fs_blocksize=$(dumpe2fs -h /dev/mmcblk0p4 2>/dev/null | awk '/Block size:/ { print $3 }')
fs_size=$(expr $fs_blocks \* $fs_blocksize / 512)

if [ $part_size -lt $target_size ]
then
	echo -n "repartitioning... "
	echo "$part_start,$target_size" | \
		sfdisk --force -uS -L -q /dev/mmcblk0 -N4 >/dev/null 2>&1
fi

utilization=$(expr $fs_size \* 100 / $part_size)
if [ $utilization -lt 95 ]
then
	echo -n "resizing... "
	resize2fs /dev/mmcblk0p4 >/dev/null 2>/dev/null
fi

echo done
