from flask import Flask, render_template
import redis
import json
import os


app = Flask(__name__)

# Connect to Redis
r = redis.Redis(host='fly-arroyo-fly-redis.upstash.io', port=6379, password=os.environ["REDIS_PASSWORD"], db=0, decode_responses=True)

def get_editors_data():
    editors_data = r.hgetall('top_editors')
    editors = [json.loads(data) for data in editors_data.values()]
    editors.sort(key=lambda x: int(x['position']))
    return editors

@app.route('/')
def index():
    editors = get_editors_data()
    return render_template('index.html', editors=editors)

@app.route('/refresh')
def refresh():
    editors = get_editors_data()
    return render_template('table_content.html', editors=editors)

if __name__ == '__main__':
    app.run(debug=True, port=5001)
