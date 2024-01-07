#!/bin/bash

. ./TermColors &> /dev/null
DIRNAME="${0%/*}"
SCRNAME="${0##*/}"
SCRNAME="${SCRNAME%.*}.conf"
CONFIGFILE="$DIRNAME/$SCRNAME"

if [ -f "$CONFIGFILE" ]
then
	. "$CONFIGFILE"
else
	echo "'$CONFIGFILE' doesn't exist. Exiting."
	exit 1
fi

TOTALFULLXFSBACKUPS=$(
	find \
		"${BACKUPDIR}/" \
		-iname '*_*_*_????-??-??-??-??-??_L0.xfs' \
		-exec stat --printf="." "{}" \;\
)

if [ "${#TOTALFULLXFSBACKUPS}" -gt 2 ]
then
	echo "More than 1 full backup. Can continue. "
else
	echo "Short on backups. Not cleaning."
	exit 2
fi

find \
	"${BACKUPDIR}/" \
	-mtime +$CLEANUPBACKUPSOLDERTHAN \
	-iname '*_*_*_????-??-??-??-??-??_L?.xfs' \
	-ls \
	-exec echo rm "{}" \+

