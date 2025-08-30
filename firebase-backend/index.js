const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const projectId = 'gen-lang-client-0477203387';  // Use project ID, not number
const location = 'us-central1';
const endpointId = '6709909346479767552';  // Fine-tuned music theory model endpoint (08/28/25)

exports.musicTheoryChat = functions
  .runWith({ memory: '512MB', timeoutSeconds: 60 })
  .https.onRequest(async (req, res) => {
    console.log('Function called with method:', req.method);
    console.log('Function called with body:', JSON.stringify(req.body));
    
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    try {
      // Get auth token if provided
      const authHeader = req.headers.authorization;
      let userId = 'anonymous';
      
      if (authHeader && authHeader.startsWith('Bearer ')) {
        const idToken = authHeader.split('Bearer ')[1];
        try {
          const decodedToken = await admin.auth().verifyIdToken(idToken);
          userId = decodedToken.uid;
          console.log('Authenticated user:', userId);
        } catch (error) {
          console.log('Auth verification failed, using anonymous:', error.message);
        }
      }

      // Get the message from request
      const {message} = req.body;
      if (!message) {
        res.status(400).json({error: 'Message is required'});
        return;
      }

      // Call Vertex AI
      const endpointUrl = `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}/locations/${location}/endpoints/${endpointId}:generateContent`;
      
      const requestBody = {
        systemInstruction: {
          parts: [{
            text: "You are a music teacher. Format your answers the same way as the fine-tuning data."
          }]
        },
        contents: [{
          role: "user",
          parts: [{text: message}]
        }],
        generationConfig: {
          temperature: 0.2,
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 2048
        }
      };

      const apiResponse = await fetch(endpointUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${await getAccessToken()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody)
      });

      const responseData = await apiResponse.json();
      
      if (!apiResponse.ok) {
        throw new Error(responseData.error?.message || 'Vertex AI request failed');
      }

      // Parse response
      const content = responseData.candidates?.[0]?.content?.parts?.[0]?.text || '';
      
      // Return response
      res.status(200).json({
        response: content,
        userId: userId
      });

    } catch (error) {
      console.error('Error:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error.message
      });
    }
  });

async function getAccessToken() {
  const {GoogleAuth} = require('google-auth-library');
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();
  return accessToken.token;
}