"""Downloads mcf_parser.py from the upstream datacommonsorg/import repository."""

import os

import requests

PARSER = 'mcf_parser.py'
PARSER_URL = (
    f'https://raw.githubusercontent.com/datacommonsorg/import/'
    f'master/simple/kg_util/{PARSER}'
)
DEST_PATH = os.path.join(
    os.path.dirname(__file__), "import", "kg_util", PARSER
)


def download():
    os.makedirs(os.path.dirname(DEST_PATH), exist_ok=True)
    print(f"Downloading {PARSER} from:\n  {PARSER_URL}")
    with open(DEST_PATH, 'w') as fw:
        fw.write(requests.get(PARSER_URL).text)
    print(f"Saved to:\n  {DEST_PATH}")


if __name__ == "__main__":
    download()
