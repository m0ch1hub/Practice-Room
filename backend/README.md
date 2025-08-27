# Practice Room Chat Backend Deployment Guide

## Prerequisites
- Google Cloud CLI installed and configured
- Node.js 20+ installed
- Access to project 1078751798332

## Step 1: Set up Service Account

```bash
# Create service account
gcloud iam service-accounts create practice-room-backend \
    --display-name="Practice Room Chat Backend"

# Grant Vertex AI permissions
gcloud projects add-iam-policy-binding 1078751798332 \
    --member="serviceAccount:practice-room-backend@1078751798332.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"
```

## Step 2: Deploy Cloud Function

```bash
cd backend

# Install dependencies
npm install

# Generate API key and deploy
chmod +x deploy.sh
./deploy.sh

# Save the API key that's printed!
```

## Step 3: Update iOS App

1. Open `PracticeRoomChat/Models/BackendService.swift`
2. Update the `apiKey` with the key from deployment
3. The backend URL is already configured

## Step 4: Test the Backend

```bash
# Test with curl
curl -X POST https://us-central1-1078751798332.cloudfunctions.net/musicTheoryChat \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{"message": "What is a major chord?"}'
```

## Monitoring

View logs:
```bash
gcloud functions logs read musicTheoryChat --limit 50
```

View metrics in Cloud Console:
- Go to Cloud Functions
- Click on musicTheoryChat
- View Metrics tab

## Troubleshooting

### Authentication Issues
- Ensure service account has Vertex AI User role
- Check that Cloud Function has the service account attached

### Rate Limiting
- Implement rate limiting using Cloud Endpoints or Apigee
- Or use Firebase Auth for user-based quotas

### Cold Starts
- Keep function warm with Cloud Scheduler pinging every 5 minutes
- Use minimum instances setting

## Security Best Practices

1. **API Key Storage**: Use iOS Keychain, not hardcoded
2. **HTTPS Only**: Always use HTTPS
3. **Input Validation**: Sanitize user inputs
4. **Rate Limiting**: Implement per-user quotas
5. **Monitoring**: Set up alerts for unusual activity

## Cost Optimization

- Cloud Function: ~$0.40 per million invocations
- Vertex AI: Based on model usage
- Set up billing alerts at $50, $100 thresholds

## Next Steps

1. Add Firebase Auth for user management
2. Implement response caching
3. Add analytics tracking
4. Set up CI/CD pipeline