#!/usr/bin/env sh

FILE_PATH=$(dirname -- "$1")
GIVEN_FILE=$(basename -- "$1")
FILENAME="$(echo $GIVEN_FILE | cut -d '.' -f1)"

YOUTUBE_ID=${FILENAME: -11}

pushd $FILE_PATH >/dev/null

# Add the ID to the ignore file
echo "$YOUTUBE_ID" >>.ignore

# Delete any files with this ID
rm -f *-$YOUTUBE_ID.*
