#!/bin/bash

#Script vars
S_GREP=`which grep`
S_SED=`which sed`
S_AWK=`which awk`
S_INPUT="$1"
S_OUTPUT="$2"

cat <<EOF
Usage: $0 pluginfolder output.json

This script extracts all the strings from Yootheme's plugin's folder and saves them in json format for translation.
Author: Ramil Valitov, ramilvalitov@gmail.com
EOF

if [[ -z $S_INPUT ]]; then
	echo "Input folder not specified"
	exit 1
fi

if [[ ! -d $S_INPUT ]]; then
	echo "Specified input directory not found"
	exit 1
fi

if [[ -z $S_OUTPUT ]]; then
	echo "Output file not specified"
	exit 1
fi

#Find all PHP files
FILESLIST=`find $S_INPUT -type f -name "*.php"`

while read -r phpfile; do
	#Analyze each PHP file
	#First scan is for standard {{ 'ABC' |trans}} strings
	LIST=`$S_GREP -E -o "\{\{[^}]+trans:?\s*(\{|\}\})" $phpfile | $S_SED -r "s/\\s*\\\\\?('|\")\\s*\\|\\s*trans:?\\s*(\{.*$|\\}\\}\\s*$)//" | $S_SED -r "s/^\\s*\\{\\{\\s*\\\\\?('|\")\\s*//" | $S_SED -e "s/\\\\\\'/'/g"`
	STRINGLIST=`echo -e "$STRINGLIST"; echo -e "$LIST"`
	
	#Second scan is for PHP invoked calls like $app['translator']->trans('ABC')
	LIST=`$S_GREP -P -o "\\->trans\\(\\s*'((?!('\\)|('\\s*,))).)*'(\\)|\\s*,)" $phpfile | $S_SED -r "s/^\\s*->trans\(\\s*'//" | $S_SED -r "s/'\\s*(,|\\))?\\s*$//" | $S_SED -e "s/\\\\\\'/'/g"`
	STRINGLIST=`echo -e "$STRINGLIST"; echo -e "$LIST"`
done <<< "$FILESLIST"

#Removing duplicate lines and sorting in alphabetical order, removing empty lines, escaping symbols for JSON:
STRINGLIST=`echo -e -n "$STRINGLIST" | $S_SED -e '/^\s*$/d' | $S_SED -e 's/"/\\\\"/g' | sort -u`

pos=0;
echo "{" > $S_OUTPUT
while read -r line; do
	if [[ $pos > 0 ]]; then
		echo -e "," >> $S_OUTPUT
	fi
    echo -e -n "\t\"$line\": \"$line\"" >> $S_OUTPUT
	pos=1
done <<< "$STRINGLIST"
echo >> $S_OUTPUT
echo -n "}" >> $S_OUTPUT

STRINGCOUNT=`echo -e "$STRINGLIST" | wc -l`
echo "Extraction complete, $STRINGCOUNT phrases found"
exit 0
