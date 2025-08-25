import Foundation

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
    
    init(authService: ServiceAccountAuth) {
        self.authService = authService
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
    
    private let endpointId = "5817141089097744384"
    
    
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
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        role: "assistant",
                        content: "Sorry, I encountered an error. Please try again.",
                        examples: []
                    )
                    self.messages.append(errorMessage)
                    self.isLoading = false
                }
            }
        }
    }
    
    func callVertexAI(message: String) async throws -> ChatMessage {
        let accessToken = try await authService.getAccessToken()
        
        let urlString = "https://us-central1-aiplatform.googleapis.com/v1/projects/\(projectId)/locations/\(location)/endpoints/\(endpointId):generateContent"
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [[
                "role": "user",
                "parts": [
                    ["text": message]
                ]
            ]],
            "generation_config": [
                "temperature": 0.7,
                "topP": 1,
                "topK": 32,
                "maxOutputTokens": 2048
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            
            let (explanation, examples) = parseStructuredResponse(text)
            return ChatMessage(role: "assistant", content: explanation, examples: examples)
        }
        
        throw NSError(domain: "ChatService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
    
    private func parseStructuredResponse(_ content: String) -> (explanation: String, examples: [MusicalExample]) {
        if let jsonData = content.data(using: .utf8),
           let jsonResponse = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            if let sectionsArray = jsonResponse["sections"] as? [[String: Any]] {
                return parseSectionsFormat(sectionsArray)
            }
            
            if let explanation = jsonResponse["explanation"] as? String {
                let examples = parseExamplesFromJSON(jsonResponse["examples"])
                return (explanation, examples)
            }
            
            if let text = jsonResponse["text"] as? String {
                return extractExamplesFromText(text)
            }
        }
        
        return extractExamplesFromText(content)
    }
    
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
    
    private func extractExamplesFromText(_ text: String) -> (explanation: String, examples: [MusicalExample]) {
        var processedText = text
        var examples: [MusicalExample] = []
        
        // Look for MIDI patterns in the text
        let midiPattern = "MIDI:([0-9,]+)(?::([0-9.]+s))?"
        let regex = try! NSRegularExpression(pattern: midiPattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
        
        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
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