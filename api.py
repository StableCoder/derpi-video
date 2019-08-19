#!/usr/bin/env python

from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from archive_endpoint import *
from search import search_endpoint

app = Flask(__name__)
api = Api(app)


class MainEndpoint(Resource):
    def get(self):
        return MainPage()


class SearchEndpoint(Resource):
    def get(self):
        return search_endpoint(request.full_path)


class ArchiveEndpoint(Resource):
    def get(self):
        return ArchiveGet()

    def post(self):
        content = request.get_json(silent=True)
        return ArchivePost(content)


api.add_resource(MainEndpoint, '/')
api.add_resource(SearchEndpoint, '/search')
api.add_resource(ArchiveEndpoint, '/archive')

if __name__ == '__main__':
    app.run(port='5002')
