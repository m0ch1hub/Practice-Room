import SwiftUI
import AVFoundation

// MARK: - Data Models
struct Moment: Identifiable {
    let id = UUID()
    let text: String
    let audioExamples: [AudioExample]
    
    // Calculate reading time based on word count
    var readingTime: TimeInterval {
        let cleanText = text.replacingOccurrences(of: "**", with: "")
                            .replacingOccurrences(of: "\\n", with: " ")
        let wordCount = cleanText.split(separator: " ").count
        // 240 words per minute = 4 words per second
        return max(1.0, Double(wordCount) / 4.0)
    }
}

struct AudioExample: Identifiable {
    let id = UUID()
    let midiNotes: [Int]
    let duration: TimeInterval
    let description: String
    let isSequential: Bool // true if notes play in sequence (|), false if together (,)
}

// MARK: - Training Data Parser
class TrainingDataLoader: ObservableObject {
    @Published var questions: [String] = []
    @Published var moments: [Moment] = []
    @Published var currentQuestionIndex: Int = 0
    
    private var trainingData: [TrainingExample] = []
    
    init() {
        loadTrainingData()
    }
    
    func loadTrainingData() {
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
        
        if questions.isEmpty {
            print("No training data loaded")
        }
    }
    
    func loadMoments(for questionIndex: Int) {
        guard questionIndex < trainingData.count else { return }
        
        let example = trainingData[questionIndex]
        
        // Get response
        if let modelContent = example.contents.first(where: { $0.role == "model" }),
           let responseText = modelContent.parts.first?.text {
            moments = parseMoments(from: responseText)
        }
    }
    
    private func parseMoments(from text: String) -> [Moment] {
        let momentTexts = text.components(separatedBy: "[MOMENT]")
        var parsedMoments: [Moment] = []
        
        for momentText in momentTexts where !momentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let audioExamples = extractAudioExamples(from: momentText)
            let cleanText = removeAudioTags(from: momentText)
            
            parsedMoments.append(Moment(
                text: cleanText,
                audioExamples: audioExamples
            ))
        }
        
        return parsedMoments
    }
    
    private func extractAudioExamples(from text: String) -> [AudioExample] {
        let pattern = "\\[AUDIO:MIDI:([^\\]]+)\\]"
        var examples: [AudioExample] = []
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    let audioData = String(text[range])
                    if let example = parseAudioData(audioData) {
                        examples.append(example)
                    }
                }
            }
        }
        
        return examples
    }
    
    private func parseAudioData(_ data: String) -> AudioExample? {
        // Format: "60,64,67:2.0s:Description" or "60|64|67:2.0s:Description"
        let parts = data.split(separator: ":")
        guard parts.count >= 2 else { return nil }
        
        let noteString = String(parts[0])
        let isSequential = noteString.contains("|")
        
        // Parse notes
        let separator = isSequential ? "|" : ","
        let midiNotes = noteString.split(separator: Character(separator))
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        // Parse duration
        let durationString = String(parts[1]).replacingOccurrences(of: "s", with: "")
        let duration = Double(durationString) ?? 1.0
        
        // Parse description (if exists)
        let description = parts.count > 2 ? String(parts[2]) : ""
        
        return AudioExample(
            midiNotes: midiNotes,
            duration: duration,
            description: description,
            isSequential: isSequential
        )
    }
    
    private func removeAudioTags(from text: String) -> String {
        let pattern = "\\[AUDIO:MIDI:[^\\]]+\\]"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            return regex.stringByReplacingMatches(
                in: text,
                range: NSRange(location: 0, length: text.count),
                withTemplate: ""
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}

// MARK: - Main Moment-Based Lesson View
struct MomentBasedLessonView: View {
    @StateObject private var dataLoader = TrainingDataLoader()
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var currentMomentIndex = 0
    @State private var isPlayingAudio = false
    @State private var showCheckmark = false
    @State private var highlightedNotes: Set<Int> = []
    @State private var selectedQuestionIndex = 0
    @State private var showQuestionSelector = false
    @Binding var isPresented: Bool
    
    // Timer for reading delay and audio playback
    @State private var readingTimer: Timer?
    @State private var audioTimer: Timer?
    
    var currentMoment: Moment? {
        guard currentMomentIndex < dataLoader.moments.count else { return nil }
        return dataLoader.moments[currentMomentIndex]
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Music Theory Lesson")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                
                // Content Area
                VStack {
                    // Text Display
                    ScrollView {
                        if let moment = currentMoment {
                            MomentTextView(text: moment.text)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 40)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    Spacer()
                    
                    // Fixed Piano Keyboard (always visible)
                    PianoKeyboardView(highlightedNotes: highlightedNotes)
                        .frame(height: 120)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
                
                // Bottom Control Bar
                HStack(spacing: 12) {
                    // Question Selector Button
                    Button(action: { showQuestionSelector = true }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    
                    // Dynamic Status/Action Area
                    HStack {
                        if showQuestionSelector {
                            // Question Selector
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(dataLoader.questions.enumerated()), id: \.offset) { index, question in
                                        Button(action: {
                                            selectQuestion(at: index)
                                        }) {
                                            Text(question)
                                                .font(.system(size: 14))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedQuestionIndex == index ? Color.blue : Color(.systemGray5))
                                                .foregroundColor(selectedQuestionIndex == index ? .white : .primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        } else {
                            // Status Text
                            Text(dataLoader.questions.isEmpty ? "Loading..." : dataLoader.questions[selectedQuestionIndex])
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        
                        // Play/Next Button
                        Button(action: handleActionButton) {
                            Image(systemName: showCheckmark ? "checkmark.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(showCheckmark ? .green : .blue)
                        }
                        .disabled(isPlayingAudio)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            if !dataLoader.questions.isEmpty {
                selectQuestion(at: 0)
            }
        }
        .sheet(isPresented: $showQuestionSelector) {
            QuestionSelectorSheet(
                questions: dataLoader.questions,
                selectedIndex: $selectedQuestionIndex,
                onSelect: { index in
                    selectQuestion(at: index)
                    showQuestionSelector = false
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func selectQuestion(at index: Int) {
        selectedQuestionIndex = index
        dataLoader.loadMoments(for: index)
        currentMomentIndex = 0
        showCheckmark = false
        highlightedNotes.removeAll()
        startMoment()
    }
    
    private func handleActionButton() {
        if showCheckmark {
            // Move to next moment
            nextMoment()
        } else if !dataLoader.moments.isEmpty {
            // Start the first moment
            startMoment()
        }
    }
    
    private func startMoment() {
        guard let moment = currentMoment else { return }
        
        // Clear previous state
        highlightedNotes.removeAll()
        showCheckmark = false
        isPlayingAudio = false
        
        // Cancel any existing timers
        readingTimer?.invalidate()
        audioTimer?.invalidate()
        
        // Start reading delay, then play audio
        readingTimer = Timer.scheduledTimer(withTimeInterval: moment.readingTime, repeats: false) { _ in
            playMomentAudio()
        }
    }
    
    private func playMomentAudio() {
        guard let moment = currentMoment else { return }
        
        isPlayingAudio = true
        
        // Play all audio examples in the moment
        var totalDuration: TimeInterval = 0
        
        for example in moment.audioExamples {
            // Highlight notes
            highlightedNotes.formUnion(example.midiNotes)
            
            // Play audio (integrate with your sound engine here)
            playAudioExample(example)
            
            totalDuration += example.duration
        }
        
        // After all audio finishes, show checkmark
        audioTimer = Timer.scheduledTimer(withTimeInterval: totalDuration, repeats: false) { _ in
            isPlayingAudio = false
            showCheckmark = true
        }
    }
    
    private func playAudioExample(_ example: AudioExample) {
        // Convert MIDI to notes and play
        for midiNote in example.midiNotes {
            // Use the playNote method that takes MIDI directly
            soundEngine.playNote(midiNote: midiNote, duration: example.duration)
        }
    }
    
    private func nextMoment() {
        // Clear highlights
        highlightedNotes.removeAll()
        showCheckmark = false
        
        // Move to next moment
        if currentMomentIndex < dataLoader.moments.count - 1 {
            currentMomentIndex += 1
            startMoment()
        } else {
            // End of lesson - could show completion or loop back
            currentMomentIndex = 0
            startMoment()
        }
    }
}

// MARK: - Supporting Views

struct MomentTextView: View {
    let text: String
    
    var body: some View {
        let parts = text.components(separatedBy: "**")
        
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index % 2 == 1 {
                    // Bold text (between **)
                    Text(part.replacingOccurrences(of: "\\n", with: "\n"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                } else if !part.isEmpty {
                    // Regular text
                    Text(part.replacingOccurrences(of: "\\n", with: "\n"))
                        .font(.system(size: 18))
                        .foregroundColor(.primary.opacity(0.9))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuestionSelectorSheet: View {
    let questions: [String]
    @Binding var selectedIndex: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    Button(action: {
                        onSelect(index)
                        dismiss()
                    }) {
                        HStack {
                            Text(question)
                                .foregroundColor(.primary)
                            Spacer()
                            if index == selectedIndex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select a Question")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}