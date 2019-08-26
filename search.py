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
    dict
        The entry of the corresponding found video. An empty object otherwise.
    """
    db = get_db()
    found = db.video.find({"youtube_data.id": single_search_term})
    for it in found:
        return entry_return_detail(it)
    return {}


def basic_or_search(searchList):
    db = get_db()
    retList = []
    finds = db.video.find(
        {"$or": [{"youtube_data.title": {"$regex": "Daniel Ingram"}}]})
    for it in finds:
        retList.append(entry_return_detail(it))
    return retList


def youtube_tag_search(searchList):
    db = get_db()
    finds = db.video.find({'youtube_data.tags': {'$all': searchList}})
    retList = []
    for it in finds:
        retList.append(entry_return_detail(it))
    return retList


def derpi_tag_search(searchList):
    db = get_db()
    finds = db.video.find({'derpi_data.tags': {'$all': searchList}})
    retList = []
    for it in finds:
        retList.append(entry_return_detail(it))
    return retList


def get_search_params(url_path):
    """
    From the full url path, this prunes it to just the query section, 
    that starts with 'q=' and ends either at the end of the line of the 
    next found '&'.

    Parameters
    ----------
    url_path : str
        The full url of the request to chop up

    Returns
    -------
    str
        The pruned query string, with any other replaced string
    """
    # Remove the '/search.json' part to get the given options
    query_params = url_path[len('/search.json?'):]

    # Find the 'q=' section, what we care about
    queryPos = query_params.find('q=')
    if queryPos == -1:
        # There's no 'q=' to grab items from, fail
        return []
    query_params = query_params[queryPos+2:]

    # Find the end of the search terms, if not the end of the string
    endPos = query_params.find('&')
    if endPos != -1:
        query_params = query_params[:endPos]

    return query_params


def search_endpoint(url_path):
    searchParams = get_search_params(url_path)

    # Replace the '-colon-' items with actual colons for the tag search
    searchParams = searchParams.replace("-colon-", ':')

    # Split the search parameters on the '+' character to get the search terms in a list
    searchTerms = searchParams.split('+')

    returnDict = {
        'search': []
    }
    foundList = youtube_tag_search(searchTerms)
    for it in foundList:
        returnDict['search'].append(it)
    return returnDict
