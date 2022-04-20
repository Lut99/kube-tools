#!/bin/env python3
# SERVICE TEST.py
#   by Lut99
#
# Created:
#   08 Mar 2022, 14:21:38
# Last edited:
#   08 Mar 2022, 14:24:39
# Auto updated?
#   Yes
#
# Description:
#   Very simple containerized web service in Flask that simply returns
#   "Hello, world!"
#

from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"
