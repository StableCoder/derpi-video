#!/usr/bin/bash

SEED_SITE=
TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$( cd -- "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FOLDER=*
FROM_YT_SCRIPT=
FROM_SEED_SCRIPT=
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
    --from-youtube)
    FROM_YT_SCRIPT=$2
    shift
    shift
    ;;
    --from-seed)
    FROM_SEED_SCRIPT=$2
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

exec 2>&1

if [ "$SEED_SITE" == "" ]; then
    echo "Need to provide a seed site to start!"
    exit 1
fi
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
            echo "!! Download of $FULL_CHANNEL / $VIDEO_ID failed from Youtube !!"
            echo "$VIDEO_ID" >> .youtube_dl_fail

            # Read the seed channel data to get all the files for the same video ID downloaded
            # Grep the lines we want: cat .channel_data | grep $VIDEO_ID
            # Then awk just the filenames we want: awk 'match($0, /a href="([^"]*)/, m) { print m[1] }'
            # Then grep the lines that DON't have '.description'
            cat .channel_data | grep -- $VIDEO_ID | awk 'match($0, /a href="([^"]*)/, m) { print m[1] }' | grep -v '.description' | while read -r LINK ; do
                # Download each item now
                curl $SEED_SITE$FULL_CHANNEL$LINK -o $LINK
                if [ $? -ne 0 ]; then
                    echo "Failed to download $VIDEO_ID from the original seed source"
                    echo "$VIDEO_ID" >> .seed_dl_fail
                    rm -f *-$VIDEO_ID*
                    exit
                fi
            done
            if [ $? -eq 0 ]; then
            echo DOING IT
                if [ "$FROM_SEED_SCRIPT" != "" ]; then
                    echo "Calling the 'FROM SEED SCRIPT' for $VIDEO_ID"
                    $FROM_SEED_SCRIPT $FULL_CHANNEL $VIDEO_ID
                fi
            fi
        else
            # Remove the useless (for us) 'formats' section from the json files.
            if [ $RM_FORMATS -eq 1 ]; then
                for FILE in ./*-$VIDEO_ID.info.json
                do
                    $SCRIPT_DIR/../clean_info_json.py "$FILE"
                done
            fi

            if [ "$FROM_YT_SCRIPT" != "" ]; then
            echo "Calling the 'FROM YOUTUBE SCRIPT' for $VIDEO_ID"
                $FROM_YT_SCRIPT $FULL_CHANNEL $VIDEO_ID
            fi

            echo "$VIDEO_ID" >> .youtube_dl_success
        fi
        sleep 31
    done < .channel_videos


    cd -- $TARGET_DIR
done