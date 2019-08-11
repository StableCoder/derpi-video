#!/usr/bin/env python

from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from archive_endpoint import *

app = Flask(__name__)
api = Api(app)


class Archive(Resource):
    def get(self):
        return ArchiveGet()

    def post(self):
        content = request.get_json(silent=True)
        return ArchivePost(content)


api.add_resource(Archive, '/archive')

if __name__ == '__main__':
    app.run(port='5002')
