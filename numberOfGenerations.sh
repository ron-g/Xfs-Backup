#!/bin/bash

 CONFFILE="${0}"
 CONFFILE="${CONFFILE##*/}"
 CONFFILE="${0%/*}/${CONFFILE%.*}.conf"

if [ ! -f "${CONFFILE}" ]
then
	echo "'${CONFFILE}' doesn't exist. Aborting."
	exit 1
else
	. "${CONFFILE}"
fi

NUMACTUAL=$(
	find \
		"$SRCDIR" \
		-type f \
		-regextype posix-extended \
		-iregex "$REGEXPTRN" \
		-printf '.' | \
			wc -c
	)

if [ $NUMACTUAL -gt $NUMWANTED ]
then
	FILES=$(
		find \
			"$SRCDIR" \
			-type f \
			-regextype posix-extended \
			-iregex "$REGEXPTRN" | \
				sort -t '_' -k4 
		)
	OLDESTGEN=$(echo -e "$FILES" | tail -n $NUMWANTED | head -n 1)
	echo "Oldest generation to keep '${OLDESTGEN##*/}'"
	OLDESTGEN="${OLDESTGEN##*/}"
	OLDESTGEN="${OLDESTGEN%_*}"
	OLDESTGEN="${OLDESTGEN##*_}"
	OLDESTGEN="${OLDESTGEN//-}"
	OLDESTGEN="${OLDESTGEN:0:12}" 
	#OLDERTHAN=$(mktemp -p $SRCDIR)
	OLDERTHAN=$(mktemp)
	touch -t "${OLDESTGEN}.00" "$OLDERTHAN"
	#stat --printf "%y\t%n\n" "$OLDERTHAN"

	find \
		"$SRCDIR" \
		-type f \
		-iname "*.${REGEXPTRN##*.}" \
		! -newer "$OLDERTHAN" \
		-ls \
		-delete

	rm $OLDERTHAN
fi
