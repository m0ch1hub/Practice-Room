#!/usr/bin/env python3
import requests
import json

API_KEY = "AIzaSyAZbk15NV3ODqKr65G4aWhMt0p24LizG0I"
URL = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"

response = requests.get(URL)

print(f"Status Code: {response.status_code}")
models = response.json().get('models', [])
for model in models:
    if 'generateContent' in model.get('supportedGenerationMethods', []):
        print(f"Model: {model['name']}")
        print(f"  Display Name: {model.get('displayName', 'N/A')}")
        print(f"  Supported Methods: {model.get('supportedGenerationMethods', [])}")
        print()