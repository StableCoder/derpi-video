#!/usr/bin/env python

# These are the command line arguments
# [1] target directory

from pymongo import MongoClient
import json
import sys
from pathlib import Path
import os
import datetime


def AddFailure(seedDir, failure):
    with open(seedDir + '/' + '.mongo_export_fail.txt', 'a') as failFile:
        failFile.write(failure)


def InsertEntry(seedDir, infoFile):
    dirPath, filename = os.path.split(infoFile)
    rootFilename = os.path.splitext(os.path.splitext(filename)[0])[0]
    globSafeRootFilename = rootFilename.replace('[', '[[]')

    with open(infoFile) as regInfoFile:
        entry = json.load(regInfoFile)

        # Derpi Info File
        if not os.path.isfile(dirPath + '/' + rootFilename + '.derpi.json'):
            # Create it now
            derpiEntry = {
                'status': 'archived',
                'archived': datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                'last_checked': datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            }

            # Video File
            files = [os.path.splitext(file)[1] for file in Path(dirPath).glob(
                './' + globSafeRootFilename + '.*') if file.suffix in ['.avi', '.mkv', '.mp4', '.webm']]
            if len(files) == 1:
                derpiEntry['video'] = dirPath + '/' + rootFilename + files[0]
            else:
                print('Error, video file for ' +
                      rootFilename + 'not found or ambiguous!')
                AddFailure(seedDir, rootFilename)
                return

            # Thumbnail File
            if os.path.isfile(dirPath + '/' + rootFilename + '.jpg'):
                derpiEntry['thumbnail'] = dirPath + '/' + rootFilename + '.jpg'
            else:
                print('Error, thumbnail file for ' +
                      entry['id'] + ' not found!')
                AddFailure(seedDir, rootFilename)
                return

            with open(dirPath + '/' + rootFilename + '.derpi.json', 'w') as outDerpiFile:
                json.dump(derpiEntry, outDerpiFile, indent=4)

        with open(dirPath + '/' + rootFilename + '.derpi.json') as derpiInfoFile:
            derpiEntry = json.load(derpiInfoFile)
            entry['derpi_data'] = derpiEntry

        # Upsert into the Mongo DB
        client = MongoClient('localhost', 27017)
        db = client.archive
        collection = db.video
        entry['_id'] = entry['id']
        collection.update_one({'_id': entry['_id']}, {
                              '$set': entry}, upsert=True)


targetDir = os.getcwd()
if len(sys.argv) > 1:
    targetDir = sys.argv[1]

for filename in Path(targetDir).glob('**/*.info.json'):
    InsertEntry(targetDir, filename)
