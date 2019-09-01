#!/usr/bin/bash

SEED_SITE=
TARGET_DIR=$(pwd)/seed-workdir
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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

# Get channels
mkdir -p $TARGET_DIR
cd $TARGET_DIR
curl $SEED_SITE > .youtube_archive

if [ $? -ne 0 ]; then
    echo "Failed to get seed data from '$SEED_SITE'"
    exit 1
fi

# Below is the regex we use to grab out the directory name for use
# alt="\[DIR\]"><\/td><td><a href="([^"]+)
cat .youtube_archive | awk 'match($0, /alt="\[DIR\]"><\/td><td><a href="([^"]+)/, m) { print m[1] }' > .channel_folders

# For each channel, create a folder, and get list out the videos for that directory/channel
while read FULL_CHANNEL; do
    echo "Downloading channel data for $FULL_CHANNEL"

    ## Go to a channel-specific folder
    mkdir -p $FULL_CHANNEL
    cd $FULL_CHANNEL

    curl $SEED_SITE$FULL_CHANNEL > .channel_data

    # Grab all the *.info.json files that are linked
    # cat channel_data | awk 'match($0, /a href="(.*\.info\.json)"/, m) { print m[1] }' > channel_videos
    # Reduce to just the Video IDs
    cat .channel_data | awk 'match($0, /a href=".*(.{11})\.info\.json"/, m) { print m[1] }' > .channel_videos

    # Give the server a moment to recover
    sleep 3s

    # Back to root seed dir
    cd $TARGET_DIR
done < .channel_folders
