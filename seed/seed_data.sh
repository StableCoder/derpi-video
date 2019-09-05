#!/usr/bin/bash

TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$( cd -- "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FOLDER=*
DELAY=20s
COMPLETE_SCRIPT=
RM_FORMATS=1

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--delay)
    DELAY=$2
    shift
    shift
    ;;
    -t|--target)
    TARGET_DIR="$2"
    shift
    shift
    ;;
    -c|--complete)
    COMPLETE_SCRIPT=$2
    shift
    shift
    ;;
    -f|--folder)
    FOLDER=$2
    shift
    shift
    ;;
    --no-prune)
    RM_FORMATS=0
    shift
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
done

if [ $RM_FORMATS -eq 1 ] && [ ! -f $SCRIPT_DIR/../clean_info_json.py ]; then
    echo "!! Cannot find the 'clean_info_json.py' script correctly, is it in the correct location?"
    exit 1
fi

cd -- $TARGET_DIR

# Now go through each channel/directory and download the videos
for FULL_CHANNEL in $FOLDER/ ; do
    echo "Downloading videos for $FULL_CHANNEL"

    cd -- $FULL_CHANNEL

    while read VIDEO_ID; do
        youtube-dl --write-info-json --write-all-thumbnails https://youtu.be/$VIDEO_ID
        if [ $? -ne 0 ]; then
            rm -f *-$VIDEO_ID*
            echo "!! Download of VideoID $VIDEO_ID failed for channel $FULL_CHANNEL !!"
            echo "$VIDEO_ID" >> .youtube_dl_fail
        else
            # Remove the useless (for us) 'formats' section from the json files.
            if [ $RM_FORMATS -eq 1 ]; then
                for FILE in ./*-$VIDEO_ID.info.json
                do
                    $SCRIPT_DIR/../clean_info_json.py "$FILE"
                done
            fi

            if [ "$COMPLETE_SCRIPT" != "" ]; then
                $COMPLETE_SCRIPT $FULL_CHANNEL $VIDEO_ID
            fi
        fi

        sleep $DELAY
    done < .channel_videos

    cd -- $TARGET_DIR
done