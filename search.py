from flask import Response
from pymongo import MongoClient


def entry_return_summary(video_entry):
    """
    Returns the basic video information, good for a summary

    Parameters
    ----------
    video_entry
        The full dict entry of the video that was retrieved from the database

    Returns
    -------
    dict
        Dict of just the summary data
    """
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
    entry['status'] = derpi_data['status']
    return entry


def entry_return_detail(video_entry):
    """
    Returns the full video data for public consumption

    This is all the information from get_entry_summary() plus more in-depth fields.

    Parameters
    ----------
    video_entry
        The full dict entry of the video that was retrieved from the database

    Returns
    -------
    dict
        Dict of detailed data
    """
    entry = entry_return_summary(video_entry)
    youtube_data = video_entry['youtube_data']
    # Add the full data
    entry['description'] = youtube_data['description']
    return entry


def get_db():
    client = MongoClient('localhost', 27017)
    return client.archive


def id_search(single_search_term):
    """
    Performs a search for a video ID using the single given string

    Parameters
    ----------
    single_search_term : string
        Search term to try to match with a video ID

    Returns
    -------
    []dict
        Array of one dict with data, if found. Empty otherwise.
    """
    db = get_db()
    found = db.video.find({"youtube_data.id": it})
    retList = []
    for it in found:
        retList.append(entry_return_summary(it))
    return retList


def basic_or_search(searchList):
    db = get_db()
    retList = []
    finds = db.video.find(
        {"$or": [{"youtube_data.title": {"$regex": "Daniel Ingram"}}]})
    for it in finds:
        retList.append(entry_return_summary(it))
    return finds.count(), retList


def youtube_tag_search(searchList):
    db = get_db()
    finds = db.video.find({'youtube_data.tags': 'gameboy'})
    retList = []
    for it in finds:
        retList.append(entry_return_summary(it))
    return finds.count(), retList


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
        found, foundList = youtube_tag_search(searchList)
        if found > 0:
            returnDict['total'] += found
            returnDict['results'].append(foundList)
    return returnDict
