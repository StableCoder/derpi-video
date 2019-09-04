#!/usr/bin/bash

SEED_SITE=
TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$( cd -- "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
COMPLETE_SCRIPT=
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
    -c|--complete)
    COMPLETE_SCRIPT=$2
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

if [ "$SEED_SITE" == "" ]; then
    echo "Need to provide a seed site to start!"
    exit 1
fi
if [ $RM_FORMATS -eq 1 ] && [ ! -f $SCRIPT_DIR/../remove_formats.py ]; then
    echo "!! Cannot find the 'remove_formats.py' script correctly, is it in the correct location?"
    exit 1
fi

cd -- $TARGET_DIR

# Now go through each channel, finding videos that could not be retrieved from youtube,
# and pull them from our seed location instead
for FULL_CHANNEL in */ ; do
    echo "Downloading unfound videos for $FULL_CHANNEL"
    
    cd -- $FULL_CHANNEL

    if [ -f ".youtube_dl_fail" ]; then
        echo "Found a file"
        # Only do stuff if any actually failed from youtube
        while read VIDEO_ID; do
            echo "Retrieving video $VIDEO_ID from seed source"

            # Read the seed channel data to get all the files for the same video ID downloaded
            # Grep the lines we want: cat .channel_data | grep $VIDEO_ID
            # Then awk just the filenames we want: awk 'match($0, /a href="([^"]*)/, m) { print m[1] }'
            # Then grep the lines that DON't have '.description'
            cat .channel_data | grep $VIDEO_ID | awk 'match($0, /a href="([^"]*)/, m) { print m[1] }' | grep -v '.description' | while read -r LINK ; do
                # Download each item now
                curl $SEED_SITE$FULL_CHANNEL$LINK -o $LINK
                if [ $? -ne 0 ]; then
                    echo "Failed to download $VIDEO_ID from the original seed source"
                    echo "$VIDEO_ID" >> .seed_dl_fail
                    break
                fi

                # Give the seed server a small break
                sleep 2
            done

            # Remove the useless (for us) 'formats' section from the json files.
            if [ $RM_FORMATS -eq 1 ]; then
                for FILE in ./*-$VIDEO_ID.info.json ; do
                    $SCRIPT_DIR/../clean_info_json.py "$FILE"
                done
            fi

            # With everything done/downloaded, we will now run the 'complete' script
            if [ "$COMPLETE_SCRIPT" != "" ]; then
                $COMPLETE_SCRIPT $FULL_CHANNEL $VIDEO_ID
            fi
            break

        done < .youtube_dl_fail
    fi

    cd -- $TARGET_DIR
done