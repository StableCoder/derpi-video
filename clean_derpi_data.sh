#!/usr/bin/env bash

# This quick script just cleans all the .derpi.json files found within the
# target directory, recursively

TARGET_DIR=$(pwd)

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--target)
    TARGET_DIR="$2"
    shift
    shift
    ;;
    *)    # unknown option
    ;;
esac
done

shopt -s globstar
rm -rf $TARGET_DIR/**/*.derpi.json