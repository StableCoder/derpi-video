from pymongo import MongoClient


def get_db():
    client = MongoClient('localhost', 27017)
    return client.archive


def create_tag(tag, description):
    """
    Attempts to create a new tag

    Parameters
    ----------
    tag : string
        The tag string
    description : string
        The description for a tag

    Returns
    -------
    bool
        True if it was added, false because it already exists
    """
    db = get_db()
    try:
        db.tags.insert_one(
            {'_id': tag, 'description': description, 'count': 0, 'alias': []})
        recount_tag(tag)
        return True
    except:
        return False


def get_tag(tag):
    """
    Returns the full entry for the given tag

    Parameters
    ----------
    tag : string
        The tag string

    Returns
    -------
    dict
        The dict of the tag, or an empty dict otherwise
    """
    db = get_db()
    finds = db.tags.find({'_id': tag})
    for it in finds:
        return it
    return dict()


def recount_tag(tag):
    """
    Counts the number of archived items that use the tag, sets it in the DB, and returns it

    Parameters
    ----------
    tag : string
        Tag name to count

    Returns
    -------
    int
        Number of archived items that use the tag
    """
    db = get_db()
    finds = db.video.count_documents({'derpi_data.tags': tag})
    db.tags.update_one({'_id': tag}, {'count': finds})
    return finds


def remove_alias(alias):
    """
    Removes an alias from being active

    Parameters
    ----------
    alias : string
        Alias to be removed
    """
    db = get_db()
    db.tags.update_many({}, {'$pull': {'alias': alias}})


def create_alias(alias, tag):
    """
    Creates an alias of the tag, if not already an alias to anything

    Parameters
    ----------
    alias : string
        Item that should point to the given tag
    tag : string
        Item that the alias should point to

    Returns
    -------
    string
        The tag that the alias points to. May point to another tag IF it is already aliased.
    """
    db = get_db()
    aliasTarget = get_alias_tag(alias)
    if aliasTarget == "":
        db.tags.update_one(
            {'_id': tag}, {'$push': {'alias': alias}})
        aliasTarget = tag
    return aliasTarget


def get_alias_tag(alias):
    """
    Returns the proper tag for any given string, if it is an alias

    Parameters
    ----------
    alias : string
        String to search for an alias of

    Returns
    -------
    string
        The proper tag if the string was an alias. Nothing if its not an alias or not found.
    """
    db = get_db()
    find = db.tags.find({'alias': alias}, {'_id': 1})
    for it in find:
        return it['_id']
    return ""
