from flask import Response
from pymongo import MongoClient


def entry_return_basic(video_entry):
    youtube_data = video_entry['youtube_data']
    derpi_data = video_entry['derpi_data']
    entry = {}
    entry['id'] = youtube_data['id']
    entry['uploader'] = youtube_data['uploader']
    entry['upload_date'] = youtube_data['upload_date']
    entry['title'] = youtube_data['title']
    entry['duration'] = youtube_data['duration']
    entry['view_count'] = youtube_data['view_count']
    entry['average_rating'] = youtube_data['average_rating']
    entry['thumbnail'] = derpi_data['thumbnail']
    return entry


def id_search(searchList):
    client = MongoClient('localhost', 27017)
    db = client.archive
    foundCount = 0
    retList = []
    for it in searchList:
        found = db.video.find({"youtube_data.id": it})
        foundCount += found.count()
        for fIt in found:
            retList.append(entry_return_basic(fIt))
    return foundCount, retList


def basic_or_search(searchList):
    client = MongoClient('localhost', 27017)
    db = client.archive
    findCount = 0
    retList = []
    finds = db.video.find({"$or": [
        {"youtube_data.title": {"$regex": "Daniel Ingram"}}]})
    findCount += finds.count()
    for it in finds:
        retList.append(entry_return_basic(it))
    return findCount, retList


def search_endpoint(url_path):
    # Remove the '/search' part to get the given options
    options = url_path[len('/search?'):]
    # Find the 'q=' section, what we care about
    queryPos = options.find('q=')
    returnDict = {}
    returnDict['total'] = 0
    returnDict['results'] = []
    if queryPos != -1:
        searchList = options[queryPos+2:].split('+')
        found, foundList = basic_or_search(searchList)
        if found > 0:
            returnDict['total'] += found
            returnDict['results'].append(foundList)

    return returnDict
