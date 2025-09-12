import Foundation
import FirebaseAuth
import FirebaseFunctions

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let examples: [MusicalExample]
}

struct MusicalExample: Identifiable, Codable {
    let id: UUID
    let type: ExampleType
    let content: String
    let displayText: String
    let instruction: String?
    
    enum ExampleType: String, Codable, CaseIterable {
        case chord = "chord"
        case scale = "scale"
        case interval = "interval"
        case note = "note"
        case chordProgression = "progression"
        case sequence = "sequence"
    }
    
    enum CodingKeys: String, CodingKey {
        case type, content, displayText, instruction
    }
    
    init(type: ExampleType, content: String, displayText: String, instruction: String? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.displayText = displayText
        self.instruction = instruction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decode(ExampleType.self, forKey: .type)
        self.content = try container.decode(String.self, forKey: .content)
        self.displayText = try container.decode(String.self, forKey: .displayText)
        self.instruction = try container.decodeIfPresent(String.self, forKey: .instruction)
    }
}

class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var selectedModel: AIModel = .tunedModel
    
    private let authService: ServiceAccountAuth
    private lazy var functions = Functions.functions()
    
    init(authService: ServiceAccountAuth) {
        self.authService = authService
        // Sign in anonymously when service initializes
        Task {
            try? await Auth.auth().signInAnonymously()
        }
    }
    
    enum AIModel: String, CaseIterable {
        case tunedModel = "tuned-model"
        
        var displayName: String {
            switch self {
            case .tunedModel: return "Music Theory AI"
            }
        }
    }
    
    private let googleCloudApiKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["GOOGLE_CLOUD_API_KEY"] as? String else {
            return "YOUR_GOOGLE_CLOUD_API_KEY"
        }
        return apiKey
    }()
    
    private let projectId = "1078751798332"
    private let location = "us-central1"
    
    // Endpoint ID for the deployed tuned model (09/12/25 Version 1, Checkpoint 10)
    private let endpointId = "1255355306385342464"
    
    
    func sendMessage(_ message: String) {
        let userMessage = ChatMessage(role: "user", content: message, examples: [])
        messages.append(userMessage)
        isLoading = true
        
        Task {
            do {
                let response = try await callVertexAI(message: message)
                await MainActor.run {
                    self.messages.append(response)
                    self.isLoading = false
                }
            } catch {
                Logger.shared.error("ChatService error: \(error.localizedDescription)")
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        role: "assistant",
                        content: "Sorry, I encountered an error: \(error.localizedDescription)\n\nPlease make sure you're authenticated with Google Cloud by running 'gcloud auth login' in Terminal.",
                        examples: []
                    )
                    self.messages.append(errorMessage)
                    self.isLoading = false
                }
            }
        }
    }
    
    func callVertexAI(message: String) async throws -> ChatMessage {
        // Use Google Cloud Function backend with fine-tuned model
        return try await callBackendAPI(message: message)
    }
    
    
    private func callBackendAPI(message: String) async throws -> ChatMessage {
        // Ensure user is authenticated
        if Auth.auth().currentUser == nil {
            Logger.shared.api("No user found, signing in anonymously...")
            try await Auth.auth().signInAnonymously()
            Logger.shared.api("Anonymous sign in successful")
        } else {
            Logger.shared.api("User already authenticated: \(Auth.auth().currentUser!.uid)")
        }
        
        // Get ID token for authentication
        let _ = try await Auth.auth().currentUser?.getIDToken()
        Logger.shared.api("Got ID token for backend call")
        
        // Call Google Cloud Function via HTTP (using fine-tuned model endpoint)
        let functionURL = "https://us-central1-gen-lang-client-0477203387.cloudfunctions.net/musicTheoryChat"
        guard let url = URL(string: functionURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("5H7slvuj3zafDkQZi12V8xzMuwY2oaE5ATO7Lxejx+c=", forHTTPHeaderField: "X-API-Key")
        
        let body = ["message": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        Logger.shared.api("Calling Firebase Function via HTTP with message: \(message)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            Logger.shared.error("HTTP request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw APIError.requestFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            Logger.shared.error("Invalid response format from Firebase Function")
            Logger.shared.error("Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw APIError.invalidResponse
        }
        
        Logger.shared.api("Firebase Function Response: \(responseText)")
        
        let (explanation, examples) = parseStructuredResponse(responseText)
        Logger.shared.api("Parsed explanation: \(explanation)")
        Logger.shared.api("Parsed examples count: \(examples.count)")
        
        return ChatMessage(role: "assistant", content: explanation, examples: examples)
    }
    
    private func callVertexAIDirect(message: String) async throws -> ChatMessage {
        // Make real API call to Vertex AI
        Logger.shared.api("Calling Vertex AI with message: \(message)")
        
        // Get access token
        guard let token = try? await authService.getAccessToken() else {
            Logger.shared.error("Failed to get access token from auth service")
            throw AuthError.authenticationFailed
        }
        Logger.shared.api("Got access token: \(token.prefix(50))...")
        
        // Prepare the request body for Gemini tuned model
        let requestBody: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": message]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 2048,
                "temperature": 0.7,
                "topP": 0.95,
                "topK": 40
            ]
        ]
        
        // For Gemini tuned models deployed as endpoints
        let urlString = "https://\(location)-aiplatform.googleapis.com/v1/projects/\(projectId)/locations/\(location)/endpoints/\(endpointId):generateContent"
        Logger.shared.api("Request URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send the request
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.shared.error("Invalid response type")
            throw APIError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            Logger.shared.error("API request failed with status \(httpResponse.statusCode): \(responseString)")
            throw APIError.requestFailed
        }
        
        // Parse Gemini response format
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Logger.shared.error("Failed to parse JSON response")
            throw APIError.invalidResponse
        }
        
        Logger.shared.api("Full response structure: \(jsonResponse)")
        
        // Gemini returns candidates array with content
        guard let candidates = jsonResponse["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            Logger.shared.error("Failed to extract text from response: \(jsonResponse)")
            throw APIError.invalidResponse
        }
        
        Logger.shared.api("Extracted text from response: \(text)")
        let (explanation, examples) = parseStructuredResponse(text)
        Logger.shared.api("Parsed explanation: \(explanation)")
        Logger.shared.api("Parsed examples count: \(examples.count)")
        return ChatMessage(role: "assistant", content: explanation, examples: examples)
    }
    
    private func parseStructuredResponse(_ content: String) -> (explanation: String, examples: [MusicalExample]) {
        // Unified parser for [MIDI:...] format
        return parseUnifiedMIDIFormat(content)
    }
    
    private func parseUnifiedMIDIFormat(_ content: String) -> (explanation: String, examples: [MusicalExample]) {
        var examples: [MusicalExample] = []
        var processedText = content
        
        // Pattern to match [MIDI:notes@start-end:label] format
        let pattern = "\\[MIDI:([^\\]]+?)@(\\d+t)-(\\d+t):([^\\]]+?)\\]"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            Logger.shared.error("Failed to create MIDI regex")
            return (content, [])
        }
        
        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..<content.endIndex, in: content))
        
        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            if match.numberOfRanges >= 5,
               let notesRange = Range(match.range(at: 1), in: content),
               let startRange = Range(match.range(at: 2), in: content),
               let endRange = Range(match.range(at: 3), in: content),
               let labelRange = Range(match.range(at: 4), in: content) {
                
                let notes = String(content[notesRange])
                let _ = String(content[startRange])  // Start ticks for future duration calculation
                let _ = String(content[endRange])    // End ticks for future duration calculation
                let label = String(content[labelRange])
                
                // Convert tick duration to seconds (assuming 960 ticks per beat at 120 BPM = 2 beats per second)
                let duration = "2.0s" // Default 2 seconds for now, can be calculated from ticks if needed
                
                // Determine the example type from the notes
                let type = inferExampleType(from: notes)
                
                // Create the musical example with the original MIDI format
                let example = MusicalExample(
                    type: type,
                    content: "MIDI:\(notes):\(duration)",
                    displayText: label
                )
                examples.append(example)
                
                // Replace the MIDI tag with AUDIO format for UI rendering
                if let fullRange = Range(match.range(at: 0), in: processedText) {
                    processedText.replaceSubrange(fullRange, with: "[AUDIO:MIDI:\(notes):\(duration):\(label)]")
                }
            }
        }
        
        Logger.shared.api("Parsed \(examples.count) MIDI examples from unified format")
        return (processedText, examples)
    }
    
    // Legacy parsing methods - kept for reference but not used
    private func parseSectionsFormat(_ sectionsArray: [[String: Any]]) -> (explanation: String, examples: [MusicalExample]) {
        var textSections: [String] = []
        var examples: [MusicalExample] = []
        var interleaved: [String] = []
        
        for section in sectionsArray {
            guard let type = section["type"] as? String,
                  let content = section["content"] as? String else {
                continue
            }
            
            if type == "text" {
                textSections.append(content)
                interleaved.append(content)
            } else if type == "audio" {
                guard let displayText = section["displayText"] as? String else {
                    continue
                }
                
                // Determine the example type from MIDI content
                let exampleType: MusicalExample.ExampleType
                if content.contains(",") {
                    if content.components(separatedBy: ",").count > 2 {
                        exampleType = .chord
                    } else {
                        exampleType = .interval
                    }
                } else {
                    exampleType = .note
                }
                
                let example = MusicalExample(
                    type: exampleType,
                    content: content,
                    displayText: displayText
                )
                examples.append(example)
                
                // Add audio marker to interleaved content
                interleaved.append("[AUDIO:\(content):\(displayText)]")
            }
        }
        
        let fullExplanation = interleaved.joined(separator: "\n\n")
        return (fullExplanation, examples)
    }
    
    private func processEmbeddedAudioExamples(_ explanation: String, examples: [MusicalExample]) -> String {
        var processedText = explanation
        
        // Find and replace [AUDIO_EXAMPLE:N] placeholders with actual audio content
        let pattern = "\\[AUDIO_EXAMPLE:(\\d+)\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: explanation, options: [], range: NSRange(explanation.startIndex..<explanation.endIndex, in: explanation))
        
        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            if let indexRange = Range(match.range(at: 1), in: explanation),
               let exampleIndex = Int(String(explanation[indexRange])),
               exampleIndex > 0 && exampleIndex <= examples.count {
                
                let example = examples[exampleIndex - 1] // Convert to 0-based index
                let audioButton = "[AUDIO:\(example.content):\(example.displayText)]"
                
                if let fullRange = Range(match.range(at: 0), in: processedText) {
                    processedText.replaceSubrange(fullRange, with: audioButton)
                }
            }
        }
        
        return processedText
    }
    
    private func parseExamplesFromJSON(_ examplesData: Any?) -> [MusicalExample] {
        guard let examplesArray = examplesData as? [[String: Any]] else {
            return []
        }
        
        var examples: [MusicalExample] = []
        for exampleDict in examplesArray {
            if let content = exampleDict["content"] as? String,
               let displayText = exampleDict["displayText"] as? String {
                
                let type: MusicalExample.ExampleType
                if let typeString = exampleDict["type"] as? String,
                   let parsedType = MusicalExample.ExampleType(rawValue: typeString) {
                    type = parsedType
                } else {
                    // Infer type from content
                    type = inferExampleType(from: content)
                }
                
                let example = MusicalExample(
                    type: type,
                    content: content,
                    displayText: displayText,
                    instruction: exampleDict["instruction"] as? String
                )
                examples.append(example)
            }
        }
        return examples
    }
    
    // Legacy method - kept for reference but not used
    private func extractExamplesFromText(_ text: String) -> (explanation: String, examples: [MusicalExample]) {
        var processedText = text
        var examples: [MusicalExample] = []
        
        // Guard against double-wrapping: collect existing [AUDIO:...] ranges first
        // so we do not re-wrap "MIDI:..." that already lives inside an [AUDIO:...] tag.
        // This was causing outputs like [AUDIO:[AUDIO:MIDI:...]:Label].
        let audioTagPattern = "\\[AUDIO:[^\\]]+\\]"
        let audioRegex = try! NSRegularExpression(pattern: audioTagPattern, options: [])
        let audioMatches = audioRegex.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
        let audioRanges: [NSRange] = audioMatches.map { $0.range }

        // Look for bare MIDI patterns in the text (outside of any [AUDIO:...] tags)
        let midiPattern = "MIDI:([0-9,]+)(?::([0-9.]+s))?"
        let regex = try! NSRegularExpression(pattern: midiPattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
        
        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            // Skip if this MIDI match sits inside an existing [AUDIO:...] tag
            let fullMatchRange = match.range(at: 0)
            let isInsideAudioTag = audioRanges.contains { audioRange in
                let startsInside = NSLocationInRange(fullMatchRange.location, audioRange)
                let endsInside = NSLocationInRange(fullMatchRange.location + fullMatchRange.length - 1, audioRange)
                return startsInside && endsInside
            }
            if isInsideAudioTag { continue }

            if let midiRange = Range(match.range(at: 1), in: text) {
                let midiNotes = String(text[midiRange])
                let duration = match.range(at: 2).location != NSNotFound ? 
                    String(text[Range(match.range(at: 2), in: text)!]) : "1.0s"
                
                let fullMidiContent = "MIDI:\(midiNotes):\(duration)"
                let displayText = generateDisplayText(from: midiNotes)
                let type = inferExampleType(from: midiNotes)
                
                let example = MusicalExample(
                    type: type,
                    content: fullMidiContent,
                    displayText: displayText
                )
                examples.append(example)
                
                // Replace with audio button in text
                if let fullRange = Range(match.range(at: 0), in: processedText) {
                    processedText.replaceSubrange(fullRange, with: "[AUDIO:\(fullMidiContent):\(displayText)]")
                }
            }
        }
        
        // Look for common chord/scale patterns even without MIDI format
        let chordPattern = "\\b([A-G][b#]?)\\s+(major|minor|dim|aug)\\b"
        let chordRegex = try! NSRegularExpression(pattern: chordPattern, options: .caseInsensitive)
        let chordMatches = chordRegex.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
        
        for match in chordMatches {
            if match.numberOfRanges >= 3,
               let rootRange = Range(match.range(at: 1), in: text),
               let typeRange = Range(match.range(at: 2), in: text) {
                let root = String(text[rootRange])
                let chordType = String(text[typeRange]).lowercased()
                
                if let midiNotes = generateMIDIForChord(root: root, type: chordType) {
                    let displayText = "\(root) \(chordType.capitalized)"
                    let example = MusicalExample(
                        type: chordType == "minor" ? .chord : .chord,
                        content: "MIDI:\(midiNotes):2.0s",
                        displayText: "Play \(displayText)"
                    )
                    examples.append(example)
                }
            }
        }
        
        return (processedText, examples)
    }
    
    private func inferExampleType(from content: String) -> MusicalExample.ExampleType {
        let noteCount = content.components(separatedBy: ",").count
        if noteCount >= 8 {
            return .scale
        } else if noteCount >= 3 {
            return .chord
        } else if noteCount == 2 {
            return .interval
        } else {
            return .note
        }
    }
    
    private func generateDisplayText(from midiNotes: String) -> String {
        let noteCount = midiNotes.components(separatedBy: ",").count
        switch noteCount {
        case 1:
            return "Play Note"
        case 2:
            return "Play Interval"
        case 3...4:
            return "Play Chord"
        case 5...7:
            return "Play Progression"
        default:
            return "Play Scale"
        }
    }
    
    private func generateMIDIForChord(root: String, type: String) -> String? {
        // Basic chord generation - you could expand this
        let noteMap = ["C": 60, "C#": 61, "Db": 61, "D": 62, "D#": 63, "Eb": 63,
                      "E": 64, "F": 65, "F#": 66, "Gb": 66, "G": 67, "G#": 68,
                      "Ab": 68, "A": 69, "A#": 70, "Bb": 70, "B": 71]
        
        guard let rootMidi = noteMap[root] else { return nil }
        
        switch type {
        case "major":
            return "\(rootMidi),\(rootMidi + 4),\(rootMidi + 7)"
        case "minor":
            return "\(rootMidi),\(rootMidi + 3),\(rootMidi + 7)"
        default:
            return nil
        }
    }
    
}

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .requestFailed:
            return "API request failed"
        case .invalidResponse:
            return "Invalid response from API"
        }
    }
}

enum AuthError: LocalizedError {
    case authenticationFailed
    
    var errorDescription: String? {
        "Failed to authenticate with Google Cloud"
    }
}