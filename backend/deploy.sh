#!/bin/bash

# Generate secure API key if not exists
if [ -z "$API_KEY" ]; then
  export API_KEY=$(openssl rand -hex 32)
  echo "Generated API Key: $API_KEY"
  echo "Save this key for your iOS app!"
fi

# Deploy Cloud Function
gcloud functions deploy musicTheoryChat \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars "API_KEY=$API_KEY" \
  --region us-central1 \
  --memory 256MB \
  --timeout 30s \
  --max-instances 100 \
  --project 1078751798332

# Get the function URL
echo "Function deployed!"
echo "URL: https://us-central1-1078751798332.cloudfunctions.net/musicTheoryChat"