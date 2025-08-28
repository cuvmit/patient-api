from flask import Flask
from gevent import pywsgi
from cohort_builder.routes import cohort_builder_routes

app = Flask(__name__)
app.register_blueprint(cohort_builder_routes)

if __name__ == "__main__":
    port = 8080
    server = pywsgi.WSGIServer(('', port), app)
    print(f"Running server on port: {port}")
    server.serve_forever()
