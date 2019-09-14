#!/usr/bin/env bash

CHANNEL="$1"
VIDEO_ID=$2
DATE=$(date --utc +%F\ %T)

# Get the last non-json and non-jpg file, presumably the video file, and echo it's extension to
# the derpi.json file
for FILE in "$(ls *-$VIDEO_ID.* | grep -v '.json' | grep -v '.jpg' | tail -n 1)" ; do
    EXTENSION="${FILE##*.}"
    FILENAME="${FILE%.*}"

    cat > "${FILENAME}.derpi.json" <<EOF
{
    "status": "available",
    "archived": "$DATE",
    "last_checked": "$DATE",
    "video_ext": "$EXTENSION"
}
EOF
done

# Move the .json files
for JSON_FILE in *-$VIDEO_ID*.json ; do
    aws s3 mv --storage-class STANDARD_IA "$JSON_FILE" "s3://st-derpi-video-json/$CHANNEL$JSON_FILE"
done

# Move the thumbnail image
for IMG_FILE in *-$VIDEO_ID.jpg ; do
    aws s3 mv --storage-class STANDARD_IA "$IMG_FILE" "s3://st-derpi-video-img/$CHANNEL$IMG_FILE"
done

# Move the video files
for VIDEO_FILE in *-$VIDEO_ID.* ; do 
    aws s3 mv --storage-class STANDARD_IA "$VIDEO_FILE" "s3://st-derpi-video-archive/$CHANNEL$VIDEO_FILE"
done