#!/usr/bin/env bash
#
# This script is used to convert arpl-i18n 23.10.4 system to RR 23.10.5 system


if [ ! "$(cat /mnt/p1/ARPL-VERSION)" = "23.10.4" ]; then
  echo "Please upgrade to 23.10.4 first"
  exit -1
fi

L1=$(blkid -L ARPL1)
[ -n "${L1}" ] && fatlabel ${L1} RR1
if [ $? -ne 0 ]; then
  echo "error: 1"
  exit 1
fi
L2=$(blkid -L ARPL2)
[ -n "${L2}" ] && e2label ${L2} RR2
if [ $? -ne 0 ]; then
  echo "error: 2"
  exit 2
fi
L3=$(blkid -L ARPL3)
[ -n "${L3}" ] && e2label ${L3} RR3
if [ $? -ne 0 ]; then
  echo "error: 3"
  exit 3
fi
hostname rr
if [ $? -ne 0 ]; then
  echo "error: 4"
  exit 4
fi

echo "==============================="
echo "Conversion is completed, please go to 'menu.sh -> update menu' immediately to update."
echo "warn:"
echo "  Now if you don’t update to RR immediately, shutdown/restart will not boot."
echo "==============================="