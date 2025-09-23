#!/usr/bin/env python3
import requests
import json

API_KEY = "AIzaSyAZbk15NV3ODqKr65G4aWhMt0p24LizG0I"
URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"

data = {
    "contents": [
        {
            "parts": [
                {
                    "text": "What is a major chord?"
                }
            ]
        }
    ]
}

headers = {
    "Content-Type": "application/json"
}

response = requests.post(URL, headers=headers, data=json.dumps(data))

print(f"Status Code: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    if 'candidates' in result:
        text = result['candidates'][0]['content']['parts'][0]['text']
        print(f"Response: {text[:500]}...")  # First 500 chars
else:
    print(f"Error: {response.json()}")