#!/bin/bash

########################################################
# Author: Evgenij Kudinov 2017
# Script for show on dwm status bar info about wlan, 
# volume, layout keyboard and current date.
# for net taken from :
# https://gist.github.com/cjsewell/96463db7fec6faeab291
# https://gist.github.com/cjsewell/a139be3c6db581da521d
########################################################


function human_readable {
        VALUE=$1
        BIGGIFIERS=( B K M G )
        CURRENT_BIGGIFIER=0
        while [ $VALUE -gt 10000 ] ;do
                VALUE=$(($VALUE/1000))
                CURRENT_BIGGIFIER=$((CURRENT_BIGGIFIER+1))
        done
        echo "$VALUE${BIGGIFIERS[$CURRENT_BIGGIFIER]}"
}

#set init values for net
TRANSMITTED1=0
RECEIVED1=0

#Timeout for update
SLP=1

#IP 
OUT_IP=""
LOCAL_IP=""

while(true)
do 
	sleep $SLP
	case "$(xset -q|grep LED| awk '{ print $10 }')" in
		"00000000") KBD="EN" ;;
		"00001004") KBD="RU" ;;
		*) KBD="unknown" ;;
	esac
	if [ -n "$(ip addr|grep wlan0|grep UP)" ];then
	    WLAN0="UP"
      [ -z $OUT_IP ] && OUT_IP=$(curl ipinfo.io/ip)
		  [ -z $LOCAL_IP ] && LOCAL_IP=$(ip addr|grep wlan0|grep inet|awk '{print $2}')
	else 
	    WLAN0="DOWN"
		  OUT_IP=""
		  LOCAL_IP=""
  fi

	DATE=$(date +"%a %b %d %T")
	VOLUME=$(awk -F "[][]" '{print $2}' <(amixer sget Master|grep Right:))        
	MUTE=$(awk -F "[][]" '{print $4}' <(amixer sget Master|grep Right:))
	if [ "$MUTE" == "off" ];then 
		VOLUME=$MUTE
	fi
	TOP="Wlan0:$WLAN0  Vol:$VOLUME  Kbd:$KBD  $DATE"
	
	# stat for memory, disk usage ans cpu load
	MEMORY=$(free -m|grep Mem|awk '{print $4}')
	DISK=$(df -h|grep "^/"|awk '{print $2-$3}')
	CPU=$(cut -d ' ' -f1 < /proc/loadavg)
	
	# net stat
	LINE=$(grep wlan0 /proc/net/dev | sed s/.*://)
	RECEIVED2=$(echo $LINE | awk '{print $1}')
	TRANSMITTED2=$(echo $LINE | awk '{print $9}')
	TOTAL=$((RECEIVED2+TRANSMITTED2))
	TR=$(human_readable "$TRANSMITTED2")
	RS=$(human_readable "$RECEIVED2")
	TT=$(human_readable $TOTAL)
	INSPEED=$(((RECEIVED2-RECEIVED1)/(SLP*1024)))
	OUTSPEED=$(((TRANSMITTED2-TRANSMITTED1)/(SLP*1024)))
	# set bottom bar
        BOTTOM="IP_L:$LOCAL_IP  IP_O:$OUT_IP  Tran:$TR  Recv:$RS  Tot:$TT  In:$INSPEED KB/s  Out:$OUTSPEED KB/s  CL:$CPU  MF:$MEMORY MB  DF:$DISK GB"
	xsetroot -name "$TOP;$BOTTOM"
	TRANSMITTED1=$TRANSMITTED2
	RECEIVED1=$RECEIVED2
done
