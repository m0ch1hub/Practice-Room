import Foundation

class MusicTheoryRAG {
    static let shared = MusicTheoryRAG()
    
    private init() {}
    
    func getReferenceContext(for userMessage: String) -> String? {
        let analysis = QueryAnalyzer.analyze(userMessage)
        
        // Use knowledge base for major chord questions
        if let concept = analysis.detectedConcept, concept == "major_chord" {
            return retrieveMajorChordContext(for: userMessage, analysis: analysis)
        }
        
        // Add more music theory topics here later
        // if matchesMinorChordQuestion(cleanMessage) { ... }
        // if matchesScaleQuestion(cleanMessage) { ... }
        
        return nil // No context found - no fallbacks
    }
    
    private func retrieveMajorChordContext(for message: String, analysis: QueryAnalysis) -> String? {
        // Search the knowledge base for relevant examples
        let examples = MusicTheoryKnowledgeBase.shared.searchExamples(
            for: message,
            concept: "major_chord",
            difficulty: analysis.inferredDifficulty,
            style: analysis.inferredStyle,
            focus: analysis.inferredFocus,
            limit: 1 // Get single best match
        )
        
        guard let bestExample = examples.first else {
            return nil // No fallbacks - fail if no exact match
        }
        
        // Return the exact JSON structure from the reference
        return bestExample.content
    }
    
}

extension ChatService {
    func sendMessageWithRAG(_ message: String) {
        Logger.shared.ui("User sent message: '\(message)'")
        Logger.shared.info("📤 USER MESSAGE: \(message)")
        
        let userMessage = ChatMessage(role: "user", content: message, examples: [])
        messages.append(userMessage)
        
        isLoading = true
        
        // Check for RAG context
        if let referenceContext = MusicTheoryRAG.shared.getReferenceContext(for: message) {
            Logger.shared.info("🎯 RAG CONTEXT FOUND: Using exact reference structure for '\(message)'")
            
            // Pass the exact JSON structure to the AI
            let enhancedPrompt = """
            COPY THIS EXACT JSON STRUCTURE:
            \(referenceContext)
            
            USER QUESTION: \(message)
            
            INSTRUCTIONS:
            - Copy the JSON above EXACTLY 
            - Do NOT change field names, structure, or MIDI specifications
            - Only make explanation text slightly more conversational
            - Return raw JSON only - no markdown formatting
            """
            
            Task {
                do {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    let response = try await callOpenAI(message: enhancedPrompt)
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    
                    await MainActor.run {
                        Logger.shared.info("RAG-enhanced API call took \(String(format: "%.2f", timeElapsed * 1000))ms")
                        Logger.shared.info("📥 RAG-ENHANCED RESPONSE: \(response.content)")
                        if !response.examples.isEmpty {
                            Logger.shared.info("🎵 RAG EXAMPLES: \(response.examples.map { $0.displayText }.joined(separator: " | "))")
                        }
                        self.messages.append(response)
                        self.isLoading = false
                    }
                } catch {
                    Logger.shared.error("RAG API call failed: \(error.localizedDescription)")
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
            return
        }
        
        // No fallbacks - if no RAG match, return error
        Logger.shared.error("❌ NO RAG MATCH: No reference found for '\(message)'")
        
        Task {
            await MainActor.run {
                let errorMessage = ChatMessage(
                    role: "assistant",
                    content: "I don't have reference material for that topic yet. Please ask about major chords.",
                    examples: []
                )
                self.messages.append(errorMessage)
                self.isLoading = false
            }
        }
    }
}