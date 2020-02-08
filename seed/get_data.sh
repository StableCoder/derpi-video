#!/usr/bin/env bash

# Colours
RED='\033[0;31m'
YELLOW='\033[0;1;33m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
NO_COLOUR='\033[0m'

# Script Vars
SEED_SITE=
TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
FOLDER=*
FROM_YT_SCRIPT=
FROM_SEED_SCRIPT=
RM_FORMATS=1

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -s | --seed)
        SEED_SITE="$2"
        shift # past argument
        shift # past value
        ;;
    -t | --target)
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
    -f | --folder)
        FOLDER=$2
        shift
        shift
        ;;
    --no-prune)
        RM_FORMATS=0
        shift
        ;;
    *) # unknown option
        echo -e "${RED}ERROR${NO_COLOUR}: Unknown option: $1\n"
        exit 1
        ;;
    esac
done

exec 2>&1

if [ "$SEED_SITE" == "" ]; then
    echo -e "${RED}ERROR${NO_COLOUR}: Need to provide a seed site to start!\n"
    exit 1
fi
if [ $RM_FORMATS -eq 1 ] && [ ! -f $SCRIPT_DIR/../clean_info_json.py ]; then
    echo -e "${RED}ERROR${NO_COLOUR}: Cannot find the 'clean_info_json.py' script correctly, is it in the correct location?\n"
    exit 1
fi

cd -- $TARGET_DIR

# Now go through each channel/directory and download the videos
for FULL_CHANNEL in $FOLDER/; do
    echo -e "${LIGHT_GREEN}Downloading videos for $FULL_CHANNEL${NO_COLOUR}\n"

    cd -- $FULL_CHANNEL

    while read VIDEO_ID; do
        # Check to see if the video was already downloaded in a prior run
        if [ -f .youtube ]; then
            if [ "$(grep -- $VIDEO_ID .youtube)" != "" ]; then
                echo -e "${GREEN}SKIP SUCCESS${NO_COLOUR}: Video $FULL_CHANNEL $VIDEO_ID previously downloaded from YouTube, skipping...\n"
                continue
            fi
        fi

        if [ -f .seed ]; then
            if [ "$(grep -- $VIDEO_ID .seed)" != "" ]; then
                echo -e "${GREEN}SKIP SUCCESS${NO_COLOUR}: Video $FULL_CHANNEL $VIDEO_ID previously downloaded from Seed, skipping...\n"
                continue
            fi
        fi

        # At this point, we're going to try to download it
        echo -e "${LIGHT_GREEN}Downloading${NO_COLOUR}: Attempting to download $FULL_CHANNEL - $VIDEO_ID"

        # First, delete any of the older files associated with this particular video
        rm *-$VIDEO_ID.*

        youtube-dl --write-info-json --write-all-thumbnails https://youtu.be/$VIDEO_ID
        if [[ $? -ne 0 ]]; then
            rm -f -- *-$VIDEO_ID*
            echo -e "${YELLOW}WARNING${NO_COLOUR}: Download of $FULL_CHANNEL $VIDEO_ID failed from YouTube\n"

            # Read the seed channel data to get all the files for the same video ID downloaded
            # Grep the lines we want: cat .channel_data | grep $VIDEO_ID
            # Then awk just the filenames we want: awk 'match($0, /a href="([^"]*)/, m) { print m[1] }'
            # Then grep the lines that DON't have '.description'
            cat .channel_data | grep -- $VIDEO_ID | awk 'match($0, /a href="([^"]*)/, m) { print m[1] }' | grep -v '.description' | while read -r LINK; do
                # Download each item now
                curl -o dl_temp -- $SEED_SITE$FULL_CHANNEL$LINK
                if [[ $? -ne 0 ]]; then
                    echo -e "${RED}ERROR${NO_COLOUR}: Failed to download $VIDEO_ID from the original seed source\n"
                    rm -f -- *-$VIDEO_ID*
                else
                    mv dl_temp $LINK
                fi
            done
            ls -- *-$VIDEO_ID.*
            if [[ $? -eq 0 ]]; then
                echo "$VIDEO_ID" >>.seed
                if [ "$FROM_SEED_SCRIPT" != "" ]; then
                    echo -e "${GREEN}SEED SUCCESS${NO_COLOUR}: Calling the 'FROM SEED SCRIPT' for $VIDEO_ID\n"
                    $FROM_SEED_SCRIPT $FULL_CHANNEL $VIDEO_ID
                fi
            fi
        else
            # Remove the useless (for us) 'formats' section from the json files.
            if [[ $RM_FORMATS -eq 1 ]]; then
                for FILE in ./*-$VIDEO_ID.info.json; do
                    $SCRIPT_DIR/../clean_info_json.py "$FILE"
                done
            fi

            if [ "$FROM_YT_SCRIPT" != "" ]; then
                echo -e "${GREEN}YOUTUBE SUCCESS${NO_COLOUR}: Calling the 'FROM YOUTUBE SCRIPT' for $VIDEO_ID\n"
                $FROM_YT_SCRIPT $FULL_CHANNEL $VIDEO_ID
            fi

            echo "$VIDEO_ID" >>.youtube
        fi
        sleep 91
    done <<<$(cat .channel_data | awk 'match($0, /a href=".*(.{11})\.description"/, m) { print m[1] }')

    cd -- $TARGET_DIR
done
