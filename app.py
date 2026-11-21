from flask import Flask

app = Flask(_name_)

@app.route("/")
def home():
    return "<h1>Student Application - Version 1</h1>"
