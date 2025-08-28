import os
import jwt
import requests
from dotenv import load_dotenv
from strands.models import BedrockModel
from opensearchpy import OpenSearch, RequestsHttpConnection
from botocore.config import Config

load_dotenv(".env")

def get_claude_sonnet_4() -> BedrockModel:
    return BedrockModel(
        model_id="us.anthropic.claude-sonnet-4-20250514-v1:0",
        region_name="us-east-1", # For us, we need to specify the region explicitly
        additional_request_fields={
            "anthropic_beta": ["interleaved-thinking-2025-05-14"],
            "thinking": {"type": "enabled", "budget_tokens": 16000},
        }, # Allow interleaved thinking and set budget tokens
        boto_client_config=Config(read_timeout=3600) # need timeout to be high for long running llm api calls
    )

def get_animals_index() -> dict:
    """
    Retrieves the full animals opensearch index description.
    """
    try:
        client = OpenSearch(
            hosts = [{"host": "vet-search-os.vmit.cucloud.net", "port": 443}],
            use_ssl = True,
            verify_certs = True,
            connection_class = RequestsHttpConnection,
            pool_maxsize = 2
        )
        index = client.indices.get(index="animals")["animals"]["mappings"]["properties"]
        # we only want the agent to know about the code field as an identifier
        # leaving in the id field will result in confusion for the agent and the end user
        del index["id"]
        return index
    except Exception as e:
        print(f"Error retrieving index description: {e}")
        return e

def get_ezyvet_species() -> list[str]:
    try:
        encoded_jwt = jwt.encode({"payload": "payload"}, os.environ.get("CUVMIT_JWT_SECRET"), algorithm="HS256")
        url = f"{os.environ.get('EZYVET_DATA_API')}/cornell/species"
        auth = f"Bearer {encoded_jwt}"
        response = requests.get(url, headers= {"Authorization": auth})
        return [r["name"] for r in response.json()]
    except Exception as e:
        print(f"Error retrieving ezyvet species list: {e}")
