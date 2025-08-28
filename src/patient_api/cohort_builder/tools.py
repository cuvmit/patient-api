from pydantic import BaseModel, Field

class CustomGrammar(BaseModel):
    query: str=Field(
        description="ANTLR custom grammar search string"
    ),
    description: str=Field(
        description="A short description justifying the query content based on the prompt and what it is meant to accomplish"
    )
