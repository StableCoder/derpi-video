import json
from pymongo import MongoClient


def GetVideoID(url):
    parseList = url.split('?')
    for it in parseList:
        if it.find("v=") != -1:
            return it[2:]
    return ""


def MainPage():
    return {'main': 'page'}


def ArchiveGet():
    client = MongoClient('localhost', 27017)
    db = client.archive
    collection = db.video
    collection.find
    return {"hell": "yeah"}


def ArchivePost(payload):
    client = MongoClient('localhost', 27017)
    db = client.archive
    collection = db.video
    videoID = GetVideoID(payload['url'])
    if videoID:
        # First, try to find it
        entry = collection.find_one({"_id": videoID})
        if entry:
            return entry
        else:
            entry = {
                "_id": videoID,
                "derpi_status": "awaiting_archive",
            }
            collection.insert_one(entry)
            return entry
