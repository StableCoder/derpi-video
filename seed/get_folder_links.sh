#!/usr/bin/bash

# Grab all the folders/channels, so that we can iterate into them
#cat youtube_archive.txt | grep /icons/folder.gif >> channel_list.txt

# Below is the regex we use to grab out the directory name for use
# <tr><td valign="top"><img src="\/icons\/folder\.gif" alt="\[DIR\]"><\/td><td><a href="([^"]+)
# cat youtube_archive.txt | awk 'match($0, /<tr><td valign="top"><img src="\/icons\/folder\.gif" alt="\[DIR\]"><\/td><td><a href="([^"]+)/, m) { print m[1] }' > channel_folders.txt

curl <url> > channel_data.txt