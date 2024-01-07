#!/bin/bash

# Provides terminal colors. Not fatal if not exist
. /scripts/TermColors &> /dev/null

# Get my directory name
DIRNAME="${0%/*}"

# Get my script name and generate from it an expected config file name
SCRNAME="${0##*/}"
SCRNAME="${SCRNAME%.*}.conf"

CONFIGFILE="${DIRNAME}/${SCRNAME}"

HOST=$(hostname)

# Provides some static variables
. "$CONFIGFILE" || ( echo "Config file missing" ; exit 1 )

function showUsage() {
	echo -e "\n$0 [full|diff|0..9] '/dev/sdX1;desc /dev/sdX2;desc'"
	return 0
}

if [ "$LOGAPPEND" == 'TRUE' ]
then
	exec &>> "$LOGFILE"
else
	exec &> "$LOGFILE"
fi

# Specify full or diff explicitly
if [ "${1,,}" == 'full' ]
then
	LEVEL=0
# Specify full or diff explicitly
elif [ "${1,,}" == 'diff' ]
then
	LEVEL=1
# Specify backup level alternatively.
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

	# Extract Device name from semicolon delimited argument
	DEVNAME="${eachdev%%;*}"

	# Extract friendly name from semicolon delimited argument
	FRIENDLYNAME="${eachdev##*;}"

	# Generate a friendly media label field for regular output and xfsdump output
	MEDIALABEL="${HOST}, '${FRIENDLYNAME}' (${DEVNAME}) Level ${LEVEL} backup on ${TIMESTAMP:0:4}/${TIMESTAMP:4:2}/${TIMESTAMP:6:2} at ${TIMESTAMP:8:2}:${TIMESTAMP:10:2}:${TIMESTAMP:12:2}"

	# Output file name
	OUTPUTFN="${BACKUPDIR}/${HOSTNAME}_${DEVNAME//\/}_${FRIENDLYNAME}_${TIMESTAMP:0:4}-${TIMESTAMP:4:2}-${TIMESTAMP:6:2}-${TIMESTAMP:8:2}-${TIMESTAMP:10:2}-${TIMESTAMP:12:2}_L${LEVEL}.xfs"

	echo -e "${GREEN}${BOLD}${MEDIALABEL} -> ${OUTPUTFN}${RESET}"

	xfsdump \
		-v verbose \
		-l $LEVEL \
		-L "$MEDIALABEL" \
		-M "$MEDIALABEL" \
		-f "$OUTPUTFN" \
		"$DEVNAME"
	echo ''
done
echo -e "${GREEN}${BOLD}Done:\t$(date +'%Y/%m/%d %H:%M:%S')${RESET}\n${SEPARATOR}\n"
