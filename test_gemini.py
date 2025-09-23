#!/usr/bin/env python3
import requests
import json

API_KEY = "AIzaSyAZbk15NV3ODqKr65G4aWhMt0p24LizG0I"
URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={API_KEY}"

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
print(f"Response: {json.dumps(response.json(), indent=2)}")