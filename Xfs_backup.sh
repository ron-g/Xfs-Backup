#!/bin/bash
#set -e
#set -u

# Provides terminal colors. Not fatal if not exist
. /scripts/TermColors &> /dev/null

# Get my directory name
DIRNAME="${0%/*}"

# Get my script name and generate from it an expected config file name
SCRNAME="${0##*/}"
SCRNAME="${SCRNAME%.*}"

CONFIGFILE="${DIRNAME}/${SCRNAME}.conf"
HOST=$(hostname)

# Provides some static variables
if [ -f "$CONFIGFILE" ]
then
	. "$CONFIGFILE"
else
	echo "Config file missing"
	exit 1
fi

if ! ls "${DIRNAME}"/*.xbu &> /dev/null
then
	printf "There are no 'xbu' files identifying backup-able sources.\n\tBackupLevel=[full|diff|0-9]\n\tDevName=/dev/sdX2\n\tFriendlyName='Home'\n"
	exit 4
fi

function showUsage() {
	printf "\n$0 [full|diff|0..9] '/dev/sdX1;desc /dev/sdX2;desc'\n\n"
	return 0
}

if [ "$LOGAPPEND" == 'TRUE' ]
then
	exec &>> "$LOGFILE"
else
	exec &> "$LOGFILE"
fi

for each in "${DIRNAME}"/*.xbu
do
	source "$each"

	if [[ "$BackupLevel" =~ [0-9] ]]
	then
		:
	elif [ "$BackupLevel" == 'full' ]
	then
		BackupLevel=0
	elif [ "$BackupLevel" == 'diff' ]
	then
		BackupLevel=1
	else
		printf "'BackupLevel' must be 'full', 'diff', or an integer 0 through 9.\n"
		exit 4
	fi

	if ! egrep -qi '/dev/.+' <<< "$DevName"
	then
		printf "That ('$DevName') doesn't appear to contain a device name.\n"
		showUsage
		exit 3
	fi

	printf "${SEPARATOR}\n${GREEN}${BOLD}Start:\t${TIMESTAMP:0:4}/${TIMESTAMP:4:2}/${TIMESTAMP:6:2} ${TIMESTAMP:8:2}:${TIMESTAMP:10:2}:${TIMESTAMP:12:2}${RESET}\n"

	TIMESTAMP=$(date +'%Y%m%d%H%M%S')

	# Generate a friendly media label field for regular output and xfsdump output
	MEDIALABEL="${HOST}, '${FriendlyName}' (${DevName}) Level ${BackupLevel} backup on ${TIMESTAMP:0:4}/${TIMESTAMP:4:2}/${TIMESTAMP:6:2} at ${TIMESTAMP:8:2}:${TIMESTAMP:10:2}:${TIMESTAMP:12:2}"

	# Output file name
	#DevName=$(sed -E "s_/_${DevSeparator}_g" <<< "$DevName")
	DevName="${DevName//\//${DevSeparator}}"
	OUTPUTFN="${BACKUPDIR}/${HOSTNAME}_${DevName}_${FriendlyName}_${TIMESTAMP:0:4}-${TIMESTAMP:4:2}-${TIMESTAMP:6:2}-${TIMESTAMP:8:2}-${TIMESTAMP:10:2}-${TIMESTAMP:12:2}_L${BackupLevel}.xfs"

	printf "${GREEN}${BOLD}${MEDIALABEL} -> ${OUTPUTFN}${RESET}\n"

	xfsdump \
		-v verbose \
		-l $BackupLevel \
		-L "$MEDIALABEL" \
		-M "$MEDIALABEL" \
		-f "$OUTPUTFN" \
		"$DevName"
	echo ''
done

printf "${GREEN}${BOLD}Done:\t$(date +'%Y/%m/%d %H:%M:%S')${RESET}\n${SEPARATOR}\n"

