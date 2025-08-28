from flask import (
    request,
    Blueprint,
    jsonify
)
from strands import Agent
from cohort_builder.tools import CustomGrammar
from utils import (
    get_claude_sonnet_4,
    get_animals_index,
    get_ezyvet_species
)

cohort_builder_routes = Blueprint("cohort_builder", __name__)

@cohort_builder_routes.post("/cohort-builder/query")
def generate_custom_query():
    try:
        prompt = request.get_json()["prompt"]
        print(prompt)

        grammar = ""
        with open("src/assets/QueryDSL.g4", "r") as fin:
            grammar = fin.read()

        SYSTEM_PROMPT = f"""
        You will be given a custom ANTLR grammar file which is used to query veterinary patient records.
        Use this to generate a structured search string that follows the rules of the \
        custom grammer based on the provided prompt.

        Custom grammar description:
        {grammar}

        The following opensearch index provides the fields that can be searched using the custom gramar:
        {get_animals_index()}

        The following list includes all possible values for the species field:
        {get_ezyvet_species()}

        Make sure to convert any common names (dog, cat, etc.) to their correct species (Canine, Feline) based on the provided list.
        Avoid querying the species field with the breed of animal and vice versa.
        Remember, when searching for specific conditions/procedures that the case notes fields will most likely contain the relevant information.

        Syntax notes:
        * Nested fields cannot be directly accessed like cases.assessment.notes
        * Proper search of nested fields requires a new bracket for each field like: cases{{assessment{{notes}}}}
        """

        agent = Agent(
            model=get_claude_sonnet_4(),
            system_prompt=SYSTEM_PROMPT
        )

        agent(
            f"Generate a custom grammar query based on the following prompt:\n{prompt}"
        )
        res = agent.structured_output(CustomGrammar)

        return jsonify({
            "query": res.query,
            "description": res.description
        }), 200
    except Exception as e:
        print(f"Error generating query: {e}")
        return jsonify({ "error": e }), 500
