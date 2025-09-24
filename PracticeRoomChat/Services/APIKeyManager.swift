import Foundation

class APIKeyManager {
    static let shared = APIKeyManager()

    private init() {}

    // Fallback for missing configuration
    private func getObfuscatedKey() -> String {
        // TEMPORARY: Replace with your new API key
        // TODO: Move to Info.plist or secure storage before App Store submission
        return "YOUR_NEW_API_KEY_HERE"  // Replace this with your actual key
    }

    var geminiAPIKey: String {
        // In production, you should:
        // 1. Store this in Info.plist or Configuration file
        // 2. Use Firebase Remote Config
        // 3. Or fetch from your backend

        // Check if key exists in Info.plist first
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !key.isEmpty {
            return key
        }

        // Fallback to obfuscated key (not recommended for production)
        return getObfuscatedKey()
    }

    // Validate API key format
    func isValidAPIKey(_ key: String) -> Bool {
        // Google API keys typically start with "AIza" and are 39 characters
        return key.hasPrefix("AIza") && key.count == 39
    }
}