import Foundation

class APIKeyManager {
    static let shared = APIKeyManager()

    private init() {}

    // Obfuscated storage - not perfect but better than plaintext
    private func getObfuscatedKey() -> String {
        // Key should be provided via Info.plist or environment variable
        // Never commit actual keys to source control
        return ""  // Placeholder - set via Info.plist
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