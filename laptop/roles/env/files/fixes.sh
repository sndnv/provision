#!/usr/bin/env bash
pointers=$(xinput | grep "Nano Transceiver" | grep "pointer" | sed 's/^.*id=\([0-9]*\)[ \t].*$/\1/')

for id in $pointers
do
  pointer_data=$(xinput list $id | grep 'Buttons supported: 9' &> /dev/null);
  if [ $? == 0 ]
  then
    xinput set-button-map $id 1 8 3 4 5 6 7 2 9
  fi
done

/usr/bin/xbacklight =35
