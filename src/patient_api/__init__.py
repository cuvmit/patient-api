import asyncio
from quart import Quart
from .cohort_builder.routes import cohort_builder_routes
from hypercorn.config import Config
from hypercorn.asyncio import serve

def run() -> None:
    app = Quart(__name__)
    app.register_blueprint(cohort_builder_routes)

    port = 8080
    config = Config()
    config.bind = [f"localhost:{port}"]

    print(f"Running server on port: {8080}")
    asyncio.run(serve(app, config))
