# Integrating Your Tuned Model

## Steps to Use Your Tuned Model in the App

### 1. Get Your Tuned Model's Endpoint ID

After your model finishes training in Vertex AI:

1. Go to [Vertex AI Model Registry](https://console.cloud.google.com/vertex-ai/models)
2. Find your tuned model (should be named something like `gemini-1.5-flash-002-tuned-XXXXXX`)
3. Click "Deploy to endpoint" if not already deployed
4. Copy the Endpoint ID (looks like: `1234567890123456`)

### 2. Deploy the Backend with Your Tuned Model

```bash
cd backend
./deploy_tuned_model.sh YOUR_ENDPOINT_ID
```

Example:
```bash
./deploy_tuned_model.sh 1234567890123456
```

This script will:
- Deploy your Cloud Function with the tuned model endpoint
- Generate a secure API key
- Show you the function URL and API key

### 3. Update Your iOS App

After deployment, update `/PracticeRoomChat/Models/BackendService.swift`:

```swift
private let backendURL = "YOUR_FUNCTION_URL"  // From deploy script output
private let apiKey = "YOUR_API_KEY"  // From deploy script output
```

### 4. Build and Run

1. Open PracticeRoomChat.xcodeproj in Xcode
2. Build and run on simulator or device
3. Your app now uses your tuned music theory model!

## Testing Your Tuned Model

Try these prompts to test your training:
- "Play C major chord"
- "What are chord inversions?"
- "Show me F major inversions"
- "Play D minor chord"

The model should respond with proper formatting including MIDI audio instructions.

## Troubleshooting

If the model isn't responding correctly:

1. **Check Deployment Status**: 
   ```bash
   gcloud ai endpoints list --region=us-central1
   ```

2. **View Function Logs**:
   ```bash
   gcloud functions logs read musicTheoryChat --region=us-central1 --limit=50
   ```

3. **Test Directly**:
   ```bash
   curl -X POST YOUR_FUNCTION_URL \
     -H "Content-Type: application/json" \
     -H "X-API-Key: YOUR_API_KEY" \
     -d '{"message": "What is a C major chord?"}'
   ```

## Next Steps

To improve your model:
1. Add more training examples (aim for 50-100)
2. Include variations in question phrasing
3. Add more music theory concepts (scales, progressions, etc.)
4. Retrain and redeploy using the same process