#!/bin/bash

. /scripts/TermColors
DIRNAME="${0%/*}"
SCRNAME="${0##*/}"
SCRNAME="${SCRNAME%.*}.conf"
CONFIGFILE="$DIRNAME/$SCRNAME"
. "$CONFIGFILE"

if [ "$LOGAPPEND" == 'TRUE' ]
then
	exec &>> "$LOGFILE"
else
	exec &> "$LOGFILE"
fi

function showUsage() {
	echo -e "\n$0 [full|diff|0..9] '/dev/sdX1;desc /dev/sdX2;desc'"
	return 0
}

if [ "${1,,}" == 'full' ]
then
	LEVEL=0
elif [ "${1,,}" == 'diff' ]
then
	LEVEL=1
elif [ "${1}" -ge 0 -a "${1}" -le 10 ]
then
	LEVEL=$1
else
	echo "Couldn't determine backup type. Exiting."
	showUsage
	exit 1
fi

if [ "${2}" == '' ]
then
	echo "No devices specified. Exiting."
	showUsage
	exit 2
elif ! egrep -qi '/dev/.+' <<< "$2"
then
	echo "That doesn't appear to contain a device name."
	showUsage
	exit 3
else
	DEVANDFRIENDLYNAME="$2"
fi

echo -e "$SEPARATOR\n${GREEN}${BOLD}Start:\t${TIMESTAMP:0:4}/${TIMESTAMP:4:2}/${TIMESTAMP:6:2} ${TIMESTAMP:8:2}:${TIMESTAMP:10:2}:${TIMESTAMP:12:2}${RESET}"
for eachdev in $DEVANDFRIENDLYNAME
do
	TIMESTAMP=$(date +'%Y%m%d%H%M%S')
	DEVNAME="${eachdev%%;*}"
	FRIENDLYNAME="${eachdev##*;}"
	MEDIALABEL="'$FRIENDLYNAME' ($DEVNAME) Level $LEVEL backup on ${TIMESTAMP:0:4}/${TIMESTAMP:4:2}/${TIMESTAMP:6:2} at ${TIMESTAMP:8:2}:${TIMESTAMP:10:2}:${TIMESTAMP:12:2}"
	#OUTPUTFN="${BACKUPDIR}/${HOSTNAME}_${DEVNAME//\/}_${FRIENDLYNAME}_L${LEVEL}_${TIMESTAMP:0:4}-${TIMESTAMP:4:2}-${TIMESTAMP:6:2}-${TIMESTAMP:8:2}-${TIMESTAMP:10:2}-${TIMESTAMP:12:2}.xfs"
	OUTPUTFN="${BACKUPDIR}/${HOSTNAME}_${DEVNAME//\/}_${FRIENDLYNAME}_${TIMESTAMP:0:4}-${TIMESTAMP:4:2}-${TIMESTAMP:6:2}-${TIMESTAMP:8:2}-${TIMESTAMP:10:2}-${TIMESTAMP:12:2}_L${LEVEL}.xfs"
	echo -e "${GREEN}${BOLD}$MEDIALABEL -> $OUTPUTFN${RESET}"
	xfsdump \
		-v verbose \
		-l $LEVEL \
		-L "$MEDIALABEL" \
		-M "$MEDIALABEL" \
		-f "$OUTPUTFN" \
		"$DEVNAME"
	echo ''
done
echo -e "${GREEN}${BOLD}Done:\t$(date +'%Y/%m/%d %H:%M:%S')${RESET}\n$SEPARATOR\n"
