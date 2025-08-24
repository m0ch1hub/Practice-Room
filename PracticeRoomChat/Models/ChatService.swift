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
    @Published var selectedModel: AIModel = .gpt5Mini
    
    enum AIModel: String, CaseIterable {
        case gpt4oMini = "gpt-4o-mini"
        case gpt5Mini = "gpt-5-mini-2025-08-07"
        
        var displayName: String {
            switch self {
            case .gpt4oMini: return "GPT-4o Mini"
            case .gpt5Mini: return "GPT-5 Mini"
            }
        }
    }
    
    private let apiKey = ""
    private let systemPrompt = """
    You are a music theory expert. Use the provided reference as inspiration and formatting guidance.
    
    INSTRUCTIONS:
    1. Generate your own explanation using your music theory knowledge
    2. Follow the same JSON structure as the reference (sections format with inline audio)
    3. Use accurate MIDI note numbers for any key (C=60, D=62, E=64, etc.)
    4. Keep the same professional, educational tone
    5. Include step-by-step explanations with audio examples
    
    REQUIRED FORMAT:
    - Always use sections format: {"sections": [{"type": "text/audio", "content": "..."}]}
    - Include inline audio with proper MIDI specs: "MIDI:60,64,67:2.0s"
    - Use clear, conversational explanations
    - Build complexity gradually
    
    Return raw JSON only - no markdown formatting.
    """
    
    func sendMessage(_ message: String) {
        // Use the new RAG-enabled method instead of direct API calls
        sendMessageWithRAG(message)
    }
    
    func callOpenAI(message: String) async throws -> ChatMessage {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": message]
        ]
        
        // Configure request based on selected model
        let requestBody: [String: Any]
        let modelName: String
        
        switch selectedModel {
        case .gpt4oMini:
            requestBody = [
                "model": "gpt-4o-mini",
                "messages": messages,
                "max_tokens": 800,
                "temperature": 0.3
            ]
            modelName = "gpt-4o-mini"
            
        case .gpt5Mini:
            requestBody = [
                "model": "gpt-5-mini-2025-08-07",
                "messages": messages,
                "max_completion_tokens": 3000,
                "verbosity": "medium",
                "reasoning_effort": "low"
            ]
            modelName = "gpt-5-mini"
        }
        
        Logger.shared.api("Sending request to OpenAI (model: \(modelName))")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.shared.api("OpenAI response status: \(httpResponse.statusCode)")
            
            // Log error details for 400 errors
            if httpResponse.statusCode == 400 {
                if let errorString = String(data: data, encoding: .utf8) {
                    Logger.shared.error("OpenAI 400 Error Details: \(errorString)")
                }
            }
            
            // Log all response data for debugging GPT-5
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.shared.api("GPT-5 Raw Response: \(responseString)")
            }
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            let (explanation, examples) = parseStructuredResponse(content)
            
            Logger.shared.api("Response parsed successfully - Content length: \(explanation.count) chars, Examples: \(examples.count)")
            
            return ChatMessage(role: "assistant", content: explanation, examples: examples)
        }
        
        Logger.shared.error("Failed to parse OpenAI response")
        throw NSError(domain: "ChatService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
    
    private func parseStructuredResponse(_ content: String) -> (explanation: String, examples: [MusicalExample]) {
        Logger.shared.info("🎯 STRUCTURED PARSING: Processing JSON response")
        
        // Parse as JSON - no fallbacks
        guard let jsonData = content.data(using: .utf8),
              let jsonResponse = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            Logger.shared.error("🎯 STRUCTURED PARSING: Failed to parse JSON response - no fallbacks")
            return ("Error: Invalid response format", [])
        }
        
        // Check for new sections-based format
        if let sectionsArray = jsonResponse["sections"] as? [[String: Any]] {
            return parseSectionsFormat(sectionsArray)
        }
        
        // Fall back to old format
        guard let explanation = jsonResponse["explanation"] as? String,
              let examplesArray = jsonResponse["examples"] as? [[String: Any]] else {
            Logger.shared.error("🎯 STRUCTURED PARSING: Invalid JSON structure - no fallbacks")
            return ("Error: Invalid response format", [])
        }
        
        let examples = examplesArray.compactMap { exampleDict -> MusicalExample? in
            guard let typeString = exampleDict["type"] as? String,
                  let type = MusicalExample.ExampleType(rawValue: typeString),
                  let content = exampleDict["content"] as? String,
                  let displayText = exampleDict["displayText"] as? String else {
                return nil
            }
            
            let instruction = exampleDict["instruction"] as? String
            return MusicalExample(
                type: type,
                content: content,
                displayText: displayText,
                instruction: instruction
            )
        }
        
        Logger.shared.info("🎼 STRUCTURED PARSING: Found \(examples.count) structured examples")
        return (explanation, examples)
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
        Logger.shared.info("🎼 SECTIONS PARSING: Found \(examples.count) interleaved examples")
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
    
}