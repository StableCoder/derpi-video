#!/usr/bin/bash

SEED_SITE=
TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
RM_FORMATS=1

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -s|--seed)
    SEED_SITE="$2"
    shift # past argument
    shift # past value
    ;;
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
    ;;
esac
done

if [ "$SEED_SITE" == "" ]; then
    echo "Need to provide a seed site to start!"
    exit 1
fi
if [ $RM_FORMATS -eq 1 ] && [ ! -f $SCRIPT_DIR/../remove_formats.py ]; then
    echo "!! Cannot find the 'remove_formats.py' script correctly, is it in the correct location?"
    exit 1
fi

# Get channels
mkdir -p $TARGET_DIR
cd $TARGET_DIR
curl $SEED_SITE > .youtube_archive.txt

if [ $? -ne 0 ]; then
    echo "Failed to get seed data from '$SEED_SITE'"
    exit 1
fi

# Below is the regex we use to grab out the directory name for use
# alt="\[DIR\]"><\/td><td><a href="([^"]+)
cat .youtube_archive.txt | awk 'match($0, /alt="\[DIR\]"><\/td><td><a href="([^"]+)/, m) { print m[1] }' > .channel_folders.txt

while read FULL_CHANNEL; do
    ## Go to a channel-specific folder
    mkdir -p $FULL_CHANNEL
    cd $FULL_CHANNEL

    curl $SEED_SITE$FULL_CHANNEL > .channel_data.txt

    # Grab all the *.info.json files that are linked
    # cat channel_data.txt | awk 'match($0, /a href="(.*\.info\.json)"/, m) { print m[1] }' > channel_videos.txt
    # Reduce to just the Video IDs
    cat .channel_data.txt | awk 'match($0, /a href=".*(.{11})\.info\.json"/, m) { print m[1] }' > .channel_videos.txt

    while read VIDEO_ID; do
        youtube-dl --write-info-json --write-all-thumbnails https://youtu.be/$VIDEO_ID
        if [ $? -ne 0 ]; then
            echo "!! Download of VideoID $VIDEO_ID failed for channel $FULL_CHANNEL !!"
            echo "$FULL_CHANNEL $VIDEO_ID" >> $TARGET_DIR/.failed_from_youtube.txt
        fi
        sleep 2s
    done < .channel_videos.txt

    # Remove the useless (for us) 'formats' section from the json files.
    if [ RM_FORMATS -eq 1 ]; then
        for FILE in ./*.info.json
        do
            $SCRIPT_DIR/../remove_formats.py "$FILE"
        done
    fi

    cd $TARGET_DIR
done < .channel_folders.txt