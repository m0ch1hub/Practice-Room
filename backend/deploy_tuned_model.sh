#!/bin/bash

# Deploy Cloud Function with Tuned Model
# Usage: ./deploy_tuned_model.sh <TUNED_MODEL_ENDPOINT_ID>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <TUNED_MODEL_ENDPOINT_ID>"
    echo "Example: $0 1234567890123456"
    echo ""
    echo "To find your tuned model endpoint ID:"
    echo "1. Go to Vertex AI > Model Registry in Google Cloud Console"
    echo "2. Find your tuned model"
    echo "3. Click on it and look for the Endpoint ID"
    exit 1
fi

TUNED_MODEL_ENDPOINT_ID=$1

# Generate a secure API key if not exists
if [ ! -f .env ]; then
    API_KEY=$(openssl rand -base64 32)
    echo "API_KEY=$API_KEY" > .env
    echo "Generated new API key: $API_KEY"
else
    source .env
    echo "Using existing API key"
fi

# Deploy function with tuned model endpoint
echo "Deploying Cloud Function with tuned model endpoint: $TUNED_MODEL_ENDPOINT_ID"

gcloud functions deploy musicTheoryChat \
    --gen2 \
    --runtime=nodejs20 \
    --region=us-central1 \
    --source=. \
    --entry-point=musicTheoryChat \
    --trigger-http \
    --allow-unauthenticated \
    --set-env-vars="API_KEY=$API_KEY,TUNED_MODEL_ENDPOINT_ID=$TUNED_MODEL_ENDPOINT_ID" \
    --memory=512MB \
    --timeout=60s

# Get the function URL
echo ""
echo "Getting function URL..."
FUNCTION_URL=$(gcloud functions describe musicTheoryChat --region=us-central1 --format='get(url)')

echo ""
echo "========================================="
echo "Deployment complete!"
echo "========================================="
echo "Function URL: $FUNCTION_URL"
echo "API Key: $API_KEY"
echo "Tuned Model Endpoint: $TUNED_MODEL_ENDPOINT_ID"
echo ""
echo "Next steps:"
echo "1. Update BackendService.swift with:"
echo "   - URL: $FUNCTION_URL"
echo "   - API Key: $API_KEY"
echo "2. Build and test your iOS app"
echo "========================================="