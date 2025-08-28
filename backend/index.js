const functions = require('@google-cloud/functions-framework');
const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');

// Configuration
const PROJECT_ID = '1078751798332';
const LOCATION = 'us-central1';
// Update this with your tuned model's endpoint ID after deployment
const ENDPOINT_ID = process.env.TUNED_MODEL_ENDPOINT_ID || '873596073128493056';

// Initialize auth client
const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

// Cache for access token
let tokenCache = {
  token: null,
  expiry: null
};

// Get access token with caching
async function getAccessToken() {
  const now = Date.now();
  
  // Check if cached token is still valid (with 5 min buffer)
  if (tokenCache.token && tokenCache.expiry && tokenCache.expiry > now + 300000) {
    console.log('Using cached token');
    return tokenCache.token;
  }
  
  console.log('Getting fresh token');
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  
  // Cache for 55 minutes (tokens last 60 min)
  tokenCache = {
    token: tokenResponse.token,
    expiry: now + (55 * 60 * 1000)
  };
  
  return tokenResponse.token;
}

// Main function to handle requests
functions.http('musicTheoryChat', async (req, res) => {
  // Enable CORS for your iOS app
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, X-API-Key');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  
  // Validate API key (you'll generate this)
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== process.env.API_KEY) {
    res.status(401).json({ error: 'Invalid API key' });
    return;
  }
  
  // Validate request
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  
  const { message } = req.body;
  if (!message) {
    res.status(400).json({ error: 'Message is required' });
    return;
  }
  
  try {
    // Get access token
    const accessToken = await getAccessToken();
    
    // Prepare request to Vertex AI
    const vertexUrl = `https://${LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/endpoints/${ENDPOINT_ID}:generateContent`;
    
    const vertexRequest = {
      contents: [
        {
          role: 'user',
          parts: [{ text: message }]
        }
      ],
      generationConfig: {
        maxOutputTokens: 2048,
        temperature: 0.5,  // Lower temperature for more consistent responses
        topP: 0.95,
        topK: 40
      }
    };
    
    // Call Vertex AI
    const response = await axios.post(vertexUrl, vertexRequest, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    // Extract response text
    const candidates = response.data.candidates || [];
    const firstCandidate = candidates[0] || {};
    const content = firstCandidate.content || {};
    const parts = content.parts || [];
    const firstPart = parts[0] || {};
    const responseText = firstPart.text || '';
    
    // Return formatted response
    res.status(200).json({
      response: responseText,
      metadata: {
        model: 'tuned-model',
        timestamp: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('Error calling Vertex AI:', error);
    
    // Return user-friendly error
    res.status(500).json({
      error: 'Failed to process request',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});