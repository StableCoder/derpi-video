#!/usr/bin/bash

TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
RM_FORMATS=1

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--target)
    TARGET_DIR="$2"
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

# Now go through each channel/directory and download the videos
for FULL_CHANNEL in */ ; do
    echo "Downloading videos for $FULL_CHANNEL"

    cd $FULL_CHANNEL

    while read VIDEO_ID; do
        youtube-dl --write-info-json --write-all-thumbnails https://youtu.be/$VIDEO_ID
        if [ $? -ne 0 ]; then
            echo "!! Download of VideoID $VIDEO_ID failed for channel $FULL_CHANNEL !!"
            echo "$VIDEO_ID" >> .youtube_dl_fail
        else
            # Remove the useless (for us) 'formats' section from the json files.
            if [ $RM_FORMATS -eq 1 ]; then
                for FILE in ./*-$VIDEO_ID.info.json
                do
                    $SCRIPT_DIR/../remove_formats.py "$FILE"
                done
            fi
        fi
        sleep 2s
    done < .channel_videos

    cd $TARGET_DIR
done