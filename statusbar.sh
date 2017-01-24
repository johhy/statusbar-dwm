#!/bin/bash

########################################################
# Author: Evgenij Kudinov 2017
# Script for show on dwm status bar info about wlan, 
# volume, layout keyboard and current date.
# for net taken from :
# https://gist.github.com/cjsewell/96463db7fec6faeab291
# https://gist.github.com/cjsewell/a139be3c6db581da521d
########################################################


function metric {
        VALUE=$1
        BIGGIFIERS=( B K M G )
        CURRENT_BIGGIFIER=0
        while [ "$VALUE" -gt 1000 ] ;do
                VALUE=$((VALUE/1000))
                CURRENT_BIGGIFIER=$((CURRENT_BIGGIFIER+1))
        done
        echo "$VALUE ${BIGGIFIERS[$CURRENT_BIGGIFIER]}"
}

function get_weather {
    CITY=Novosibirsk
    TEMP=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$OWM_KEY&units=metric"|awk -F ":" 'match($0,/"temp":[-|+]*[0-9]+/) {a=substr($0,RSTART,RLENGTH);b=substr(a,8,RLENGTH);print b}')
    echo "$TEMP C"
}

#set key api from argument of script
OWM_KEY=$1
TMP=$(get_weather)

#set init values for net
TRANSMITTED1=0
RECEIVED1=0

#Timeout for update sec
SLP=1

#Timout between get_weather request sec
GWT=$((60*60))

#Init time for timer
LAST_T=$(date +%s)

#IP
OUT_IP=""
LOCAL_IP=""

while(true)
do
	sleep $SLP

  CURRENT_T=$(date +%s)
  #check for weather request
  [ $((CURRENT_T-LAST_T)) -gt $GWT ] && TMP=$(get_weather) && LAST_T=$CURRENT_T

	case "$(xset -q|grep LED| awk '{ print $10 }')" in
		"00000000") KBD="EN" ;;
    "00000001") KBD="EN" ;;
		"00001004") KBD="RU" ;;
    "00001005") KBD="RU" ;;
		*) KBD="unknown" ;;
	esac
	if ip addr | grep -q 'wlan0.*UP'
  then
	    WLAN0="UP"
      [ -z $OUT_IP ] && OUT_IP=$(curl -s ipinfo.io/ip)
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

	TOP="Wlan0:$WLAN0 Vol:$VOLUME Kbd:$KBD T:$TMP $DATE"

	# stat for memory, disk usage ans cpu load
	MEMORY=$(free -m|grep '-'|awk '{print $4}')
	DISK=$(df -h|grep "^/"|awk '{print $2-$3}')
	CPU=$(cut -d ' ' -f1 < /proc/loadavg)

	# net stat
	LINE=$(grep wlan0 /proc/net/dev | sed s/.*://)
	RECEIVED2=$(echo "$LINE" | awk '{print $1}')
	TRANSMITTED2=$(echo "$LINE" | awk '{print $9}')
	TR=$(metric "$TRANSMITTED2")
	RS=$(metric "$RECEIVED2")
	INSPEED=$(printf "%sit/s" "$(metric $(((RECEIVED2-RECEIVED1)*8/SLP)))") # in bit/sec
	OUTSPEED=$(printf "%sit/s" "$(metric $(((TRANSMITTED2-TRANSMITTED1)*8/SLP)))") # in bit/sec

	# set bottom bar
  BOTTOM="IP_L:$LOCAL_IP  IP_O:$OUT_IP  CPU:$CPU  MF:$MEMORY MB  DF:$DISK GB  Sent:$TR  Recv:$RS  In:$INSPEED  Out:$OUTSPEED"
	xsetroot -name "$TOP;$BOTTOM"
	TRANSMITTED1=$TRANSMITTED2
	RECEIVED1=$RECEIVED2
done
