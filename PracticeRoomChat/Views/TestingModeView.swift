//
//  TestingModeView.swift
//  Practice Room: Chat
//
//  Created for testing training data without API calls
//

import SwiftUI
import AVFoundation

// MARK: - Data Models
struct TrainingExample: Codable {
    struct Content: Codable {
        let role: String
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
    
    let contents: [Content]
}

// MARK: - Testing Mode View
struct TestingModeView: View {
    @State private var trainingData: [TrainingExample] = []
    @State private var questions: [String] = []
    @State private var selectedQuestionIndex: Int = 0
    @State private var currentResponse: String = ""
    @State private var showingResponse: Bool = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Testing Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Question Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a Question:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("Question", selection: $selectedQuestionIndex) {
                        ForEach(0..<questions.count, id: \.self) { index in
                            Text(questions[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Get Response Button
                Button(action: {
                    loadResponse()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Get Response")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Response Display
                if showingResponse {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Response:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(formatResponse(currentResponse))
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            
                            // Audio Examples Section
                            if let audioExamples = extractAudioExamples(from: currentResponse), !audioExamples.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Audio Examples Found:")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(audioExamples, id: \.self) { example in
                                        HStack {
                                            Image(systemName: "music.note")
                                                .foregroundColor(.blue)
                                            Text(example)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            loadTrainingData()
        }
    }
    
    // MARK: - Helper Functions
    private func loadTrainingData() {
        // Use centralized manager to load training data
        let examples = TrainingDataManager.shared.loadTrainingExamples()
        trainingData = examples
        
        // Extract questions
        for example in examples {
            if let userContent = example.contents.first(where: { $0.role == "user" }),
               let questionText = userContent.parts.first?.text {
                questions.append(questionText)
            }
        }
        
        // Add default if no data loaded
        if questions.isEmpty {
            questions = ["No training data found"]
        }
    }
    
    private func loadResponse() {
        guard selectedQuestionIndex < trainingData.count else {
            currentResponse = "No response available"
            showingResponse = true
            return
        }
        
        let example = trainingData[selectedQuestionIndex]
        
        // Get response
        if let modelContent = example.contents.first(where: { $0.role == "model" }),
           let responseText = modelContent.parts.first?.text {
            currentResponse = responseText
            showingResponse = true
        } else {
            currentResponse = "No response found for this question"
            showingResponse = true
        }
    }
    
    private func formatResponse(_ response: String) -> String {
        var formatted = response
        formatted = formatted.replacingOccurrences(of: "**", with: "")
        formatted = formatted.replacingOccurrences(of: "\\n", with: "\n")
        
        // Remove audio tags for display
        let pattern = "\\[AUDIO:MIDI:[^\\]]+\\]"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            formatted = regex.stringByReplacingMatches(
                in: formatted,
                range: NSRange(location: 0, length: formatted.count),
                withTemplate: "♪"
            )
        }
        
        return formatted
    }
    
    private func extractAudioExamples(from text: String) -> [String]? {
        let pattern = "\\[AUDIO:MIDI:([^\\]]+)\\]"
        var examples: [String] = []
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    examples.append(String(text[range]))
                }
            }
        }
        
        return examples.isEmpty ? nil : examples
    }
}

#Preview {
    TestingModeView()
}