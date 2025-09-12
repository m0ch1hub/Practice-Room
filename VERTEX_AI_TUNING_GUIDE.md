# Vertex AI Model Tuning & Deployment Guide

This guide documents the complete process for fine-tuning a Gemini model on Vertex AI and integrating it into the iOS app.

## Overview
The app uses a custom-tuned Gemini model to provide music theory responses with specific formatting for audio playback.

## Current Configuration
- **Project ID**: `gen-lang-client-0477203387`
- **Project Number**: `1078751798332`
- **Region**: `us-central1`
- **Current Tuned Model Endpoint**: `3813531836127117312`
- **Cloud Function**: `musicTheoryChat`

## Training Data Structure

### File Format
Training data must be in JSONL format with Gemini's structure:
```json
{"contents": [{"role": "user", "parts": [{"text": "question"}]}, {"role": "model", "parts": [{"text": "answer"}]}]}
```

### Important Notes
- Each line must be valid JSON (no missing newlines between objects)
- Use `"contents"` not `"messages"` (Gemini format, not OpenAI)
- Audio instructions use format: `[AUDIO:MIDI:60,64,67:2.0s:Play C Major]`

### Current Training Files
Located in `/PracticeRoomChat/Training Data/`:
- `training_data.jsonl` - Clean training examples (16 examples covering major/minor chords and inversions)

## Step-by-Step Tuning Process

### 1. Prepare Training Data
```bash
# Navigate to training data directory
cd "/Users/mochi/Documents/Practice Room Chat/PracticeRoomChat/Training Data"

# Validate the training data
python3 -c "
import json
with open('training_data.jsonl', 'r') as f:
    for i, line in enumerate(f, 1):
        json.loads(line)
        print(f'Line {i}: Valid')
print('All lines valid!')
"

# Upload to Google Cloud Storage
gcloud storage cp training_data.jsonl gs://music-theory-training/
```

### 2. Create Tuned Model in Vertex AI Console
1. Go to: https://console.cloud.google.com/vertex-ai/generative/language/tuning
2. Click "Create tuned model"
3. Select base model: `gemini-1.5-flash-002`
4. Configure:
   - Training data: `gs://music-theory-training/training_data.jsonl`
   - Enable model validation: ❌ (only 16 examples, too few for validation split)
5. Start tuning (takes ~30-45 minutes)

### 3. Deploy Tuned Model
After training completes:
1. Click "View model details" 
2. Click "Deploy to endpoint"
3. Settings:
   - Endpoint name: `music-theory-tuned-endpoint`
   - Location: `us-central1`
   - Access: Standard
   - Machine type: `n1-standard-2` (cheapest viable option)
4. Deploy (takes 5-10 minutes)
5. Copy the Endpoint ID (looks like: `3813531836127117312`)

### 4. Enable Required APIs
These must be enabled for Cloud Functions:
```bash
gcloud services enable cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  --project=gen-lang-client-0477203387
```

### 5. Deploy Backend Cloud Function
```bash
cd "/Users/mochi/Documents/Practice Room Chat/backend"

# Generate API key if needed
API_KEY=$(openssl rand -base64 32)

# Deploy with tuned model endpoint
gcloud functions deploy musicTheoryChat \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=musicTheoryChat \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars="API_KEY=$API_KEY,TUNED_MODEL_ENDPOINT_ID=YOUR_ENDPOINT_ID" \
  --memory=512MB \
  --timeout=60s \
  --project=gen-lang-client-0477203387
```

### 6. Update iOS App
There are TWO places that need updating with your tuned model:

#### A. Update BackendService.swift 
Update `/PracticeRoomChat/Models/BackendService.swift`:
```swift
private let backendURL = "https://us-central1-gen-lang-client-0477203387.cloudfunctions.net/musicTheoryChat"
private let apiKey = "YOUR_API_KEY_FROM_DEPLOYMENT"
```

#### B. Update ChatService.swift (CRITICAL!)
Update `/PracticeRoomChat/Models/ChatService.swift`:

1. **Update the endpoint ID** (around line 89):
```swift
// Endpoint ID for the deployed tuned model
private let endpointId = "YOUR_NEW_ENDPOINT_ID"  // e.g., "3813531836127117312"
```

2. **Update the Function URL** (around line 139):
```swift
// Call Firebase Function via HTTP (using Google Cloud Function with tuned model)
let functionURL = "https://us-central1-gen-lang-client-0477203387.cloudfunctions.net/musicTheoryChat"
```

3. **Update the API Key authentication** (around line 147):
```swift
request.setValue("YOUR_API_KEY", forHTTPHeaderField: "X-API-Key")
```

**Note**: Remove any Firebase Bearer token authentication and replace with X-API-Key header.

### 7. Clean Up Old Endpoints (IMPORTANT!)
Deployed endpoints cost $50-200+/month each:
1. Go to: https://console.cloud.google.com/vertex-ai/online-prediction/endpoints
2. Undeploy models from old endpoints
3. Delete empty endpoints
4. Keep only the currently used endpoint

## Testing the Integration

### Test Cloud Function Directly
```bash
curl -X POST https://us-central1-gen-lang-client-0477203387.cloudfunctions.net/musicTheoryChat \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{"message": "What is a C major chord?"}'
```

### Expected Response Format
```json
{
  "response": "**C Major Chord**\n\nHere's your C major chord...\n[AUDIO:MIDI:60,64,67:2.0s:Play C Major Chord]",
  "metadata": {
    "model": "tuned-model",
    "timestamp": "2025-08-27T..."
  }
}
```

## Troubleshooting

### Common Issues

1. **"Failed to parse line" error during training**
   - Check for missing newlines between JSON objects
   - Ensure using `"contents"` not `"messages"` format
   - Validate JSON: `python3 -m json.tool < file.jsonl`
   - **CRITICAL**: Model responses must be plain text with [AUDIO:MIDI:...] tags, NOT nested JSON strings

2. **APIs not enabled errors**
   - Enable all required APIs (see Step 4)
   - Wait 1-2 minutes for propagation

3. **Deployment timeouts**
   - Cloud Functions can take 5-10 minutes to deploy
   - Check status: `gcloud functions describe musicTheoryChat --region=us-central1`

4. **High costs**
   - Undeploy unused endpoints immediately
   - Use `n1-standard-2` machine type (cheapest)
   - Monitor at: https://console.cloud.google.com/vertex-ai/online-prediction/endpoints

5. **401 Unauthorized errors from iOS app**
   - Make sure ChatService.swift uses `X-API-Key` header, not Firebase Bearer token
   - Verify the API key matches what was deployed to Cloud Functions
   - Check that the function URL is correct (should be gen-lang-client-0477203387, not practice-room-869ad)

6. **Multiple backends confusion**
   - `/backend/index.js` - Google Cloud Function (primary, what we use)
   - `/firebase-backend/index.js` - Firebase Function (backup/alternative)
   - ChatService.swift should point to Google Cloud Function URL

7. **Model outputs its thinking process/JSON instead of clean response**
   - Root cause: Training data had nested JSON (response as JSON string inside JSON)
   - Solution: Ensure training data has clean text responses with [AUDIO:MIDI:...] tags
   - Bad format: `{"text": "{\"sections\": [..."}` 
   - Good format: `{"contents": [{"role": "model", "parts": [{"text": "Plain text with [AUDIO:MIDI:...]"}]}]}`
   - Retrain model with cleaned data

### Viewing Logs
```bash
# Cloud Function logs
gcloud functions logs read musicTheoryChat --region=us-central1 --limit=50

# List all functions
gcloud functions list --project=gen-lang-client-0477203387
```


## Files Reference
- Backend: `/backend/index.js`
- Deploy script: `/backend/deploy_tuned_model.sh`
- iOS integration: `/PracticeRoomChat/Models/BackendService.swift`
- Training data: `/PracticeRoomChat/Training Data/*.jsonl`

## Support
For issues with the tuned model or deployment, check:
- Vertex AI Console: https://console.cloud.google.com/vertex-ai
- Cloud Functions: https://console.cloud.google.com/functions
- Cloud Logs: https://console.cloud.google.com/logs
