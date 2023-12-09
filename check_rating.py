#!/usr/bin/env python3

import requests
import json
import os
from bs4 import BeautifulSoup

def get_app_rating(app_id):

    # URL of the web page
    url = f'https://apps.apple.com/us/app/id{app_id}'

    # Send a request to the URL
    response = requests.get(url)

    # Check if the request was successful
    if response.status_code != 200:
        return {'APP_RATING': 0}

    # Use BeautifulSoup to parse the HTML content
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find the script tag with the JSON content
    script_tag = soup.find('script', {'name': 'schema:software-application', 'type': 'application/ld+json'})

    # Check if the script tag is found
    if not script_tag:
        return {'APP_RATING': 0}

    # Load the JSON content
    json_data = json.loads(script_tag.string)

    # Extract the rating value
    rating_value = json_data.get('aggregateRating', {}).get('ratingValue', 'No rating')

    # Return the rating
    return {'APP_RATING': rating_value}

if __name__ == "__main__":
    result = get_app_rating(os.environ.get('APP_ID'))
    print(result)