#!/usr/bin/env python

import time
from time import ctime
from pymongo import MongoClient
import datetime
import subprocess

if __name__ == '__main__':
    client = MongoClient('localhost', 27017)
    db = client.archive
    video_collection = db.video
    while True:
        cursor = video_collection.find({"derpi_status": "awaiting_archive"})
        for it in cursor:
            video_collection.update_one({"_id": it['_id']}, {"$set": {
                                        "derpi_status": "archiving", "derpi_archive_datetime": datetime.datetime.utcnow()}})
            subprocess.run(["youtube-dl", "--write-info-json",
                            "--write-all-thumbnails", "--skip-download", it['_id']])
