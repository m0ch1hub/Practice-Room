import Foundation

class GeminiService: ObservableObject {
    private var apiKey: String {
        return APIKeyManager.shared.geminiAPIKey
    }
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    func sendMessage(_ message: String) async throws -> String {
        // Debug: Check if API key is loaded
        if apiKey.isEmpty {
            throw GeminiError.invalidURL  // Key not found
        }

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the system instruction with all training examples
        let systemInstruction = getSystemPrompt()

        let requestBody = GeminiRequest(
            contents: [
                Content(parts: [Part(text: message)])
            ],
            systemInstruction: Content(parts: [Part(text: systemInstruction)])
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Response received successfully

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                throw GeminiError.invalidResponse
            }

            // Try to decode the response
            do {
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

                guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
                    // Try to parse JSON directly as a fallback
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        return text
                    }
                    throw GeminiError.noContent
                }

                return text
            } catch DecodingError.keyNotFound(_, _) {
                throw GeminiError.invalidResponse
            }
        } catch {
            throw error
        }
    }
}

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [Content]
    let systemInstruction: Content?
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]?
}

struct Candidate: Codable {
    let content: ResponseContent?
}

struct ResponseContent: Codable {
    let parts: [ResponsePart]?
    let role: String?
}

struct ResponsePart: Codable {
    let text: String?
}

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .noContent:
            return "No content in response"
        }
    }
}

// MARK: - System Prompt
extension GeminiService {
    private func getSystemPrompt() -> String {
        return GeminiService.systemPrompt
    }
}