#!/usr/bin/env python

from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from search import id_search, search_endpoint

app = Flask(__name__)
api = Api(app)


class VideoEndpoint(Resource):
    def get(self,  video_id):
        return id_search(video_id)


class SearchEndpoint(Resource):
    def get(self):
        return search_endpoint(request.full_path)


api.add_resource(VideoEndpoint, '/<video_id>.json')

api.add_resource(SearchEndpoint, '/search.json')

if __name__ == '__main__':
    app.run(port='5002')
