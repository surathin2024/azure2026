from flask import Flask
 
app = Flask(__name__)
 
@app.route("/")
def home():
    return "<h1>Student Application - Version 3 - Welcome to 6F</h1>"
