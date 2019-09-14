#!/usr/bin/env bash

CURRENT_TIME=$(date -u +%F\ %X)
VIDEO_ID=$2

for FILE in "$(find . -type f \( -name "*-$VIDEO_ID.*" ! -name "*.json" ! -name "*.jpg" \))" ; do
    FILENAME="${FILE%.*}"
    EXTENSION="${FILE##*.}"
    echo $FILENAME
    echo $EXTENSION
    tee "$FILENAME.derpi.json" <<EOF
{
    "status": "available",
    "archived": "$CURRENT_TIME",
    "last_checked": "$CURRENT_TIME",
    "video_ext": "$EXTENSION"
}
EOF
done