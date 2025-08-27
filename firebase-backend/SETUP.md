# Firebase Setup - Simple Steps

## 1. Create Firebase Project (5 minutes)
1. Go to https://console.firebase.google.com
2. Click "Create a project"
3. Name it: "practice-room-chat"
4. Enable Google Analytics (optional)
5. Wait for project creation

## 2. Enable Authentication
1. In Firebase Console, click "Authentication" in left menu
2. Click "Get started"
3. Click "Email/Password" and enable it
4. Click "Sign-in with Apple" and enable it (for iOS)

## 3. Deploy the Backend
Open Terminal and run these commands:

```bash
# Install Firebase tools
npm install -g firebase-tools

# Login to Firebase
firebase login

# Go to backend folder
cd firebase-backend

# Install dependencies
npm install

# Deploy
firebase deploy --only functions
```

## 4. Add Firebase to iOS App
1. In Firebase Console, click gear icon → "Project settings"
2. Click "Add app" → iOS
3. Enter bundle ID: com.yourcompany.PracticeRoomChat
4. Download GoogleService-Info.plist
5. Add it to your Xcode project

## 5. Update iOS Code
Add these packages in Xcode:
- Firebase SDK
- FirebaseAuth
- FirebaseFunctions

That's it! Your backend is ready.