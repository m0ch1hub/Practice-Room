import Foundation

class BackendService: ObservableObject {
    @Published var isAuthenticated = true
    
    // Production backend URL with tuned model
    private let backendURL = "https://us-central1-gen-lang-client-0477203387.cloudfunctions.net/musicTheoryChat"
    
    // API Key - in production, store this securely in Keychain
    private let apiKey = "Cb1k3kbIFJCbdtomV8bQKLWXAZ2pwE+dA62GwZRpdRQ="
    
    func callMusicTheoryAPI(message: String) async throws -> String {
        guard let url = URL(string: backendURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        let body = ["message": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw APIError.invalidResponse
        }
        
        return responseText
    }
}