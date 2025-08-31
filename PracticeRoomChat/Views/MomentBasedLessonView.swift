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
    let isChordProgression: Bool // true if this represents multiple chords
    let chords: [[Int]]? // For chord progressions, each array is a chord
    let durations: [TimeInterval]? // Multiple durations for ritardando or chord timing
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
        // or chord progression: "60,64,67|72,76,79:1.0s,1.5s:Description"
        let parts = data.split(separator: ":")
        guard parts.count >= 2 else { return nil }
        
        let noteString = String(parts[0])
        let durationString = String(parts[1])
        let description = parts.count > 2 ? String(parts[2]) : ""
        
        // Check if this is a chord progression (contains both | and ,)
        let isChordProgression = noteString.contains("|") && noteString.contains(",")
        
        // Parse durations (can be multiple)
        let durationComponents = durationString.split(separator: ",")
        let durations = durationComponents.compactMap { component -> TimeInterval? in
            let cleanDuration = component.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "s", with: "")
            return Double(cleanDuration)
        }
        
        if isChordProgression {
            // Parse as chord progression
            let chordStrings = noteString.split(separator: "|")
            let chords = chordStrings.map { chordString -> [Int] in
                chordString.split(separator: ",")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            }
            
            // Flatten for backward compatibility
            let allNotes = chords.flatMap { $0 }
            
            return AudioExample(
                midiNotes: allNotes,
                duration: durations.first ?? 1.0,
                description: description,
                isSequential: true, // Chord progressions play sequentially
                isChordProgression: true,
                chords: chords,
                durations: durations.count > 1 ? durations : nil
            )
        } else {
            // Original parsing logic
            let isSequential = noteString.contains("|")
            let separator = isSequential ? "|" : ","
            let midiNotes = noteString.split(separator: Character(separator))
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            
            return AudioExample(
                midiNotes: midiNotes,
                duration: durations.first ?? 1.0,
                description: description,
                isSequential: isSequential,
                isChordProgression: false,
                chords: nil,
                durations: durations.count > 1 ? durations : nil
            )
        }
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
    @State private var showPlayButton = false
    @State private var showCheckmark = false
    @State private var highlightedNotes: Set<Int> = []
    @State private var selectedQuestionIndex = 0
    @State private var showQuestionSelector = false
    @Binding var isPresented: Bool
    
    // Timer for audio playback duration
    @State private var audioTimer: Timer?
    @State private var readingTimer: Timer?
    
    // Keyboard display parameters
    @State private var keyboardStartNote: Int = 72  // Default C5
    @State private var keyboardEndNote: Int = 84    // Default C6 (one octave)
    @State private var keyboardScaleFactor: CGFloat = 1.0
    
    var currentMoment: Moment? {
        guard currentMomentIndex < dataLoader.moments.count else { return nil }
        return dataLoader.moments[currentMomentIndex]
    }
    
    var buttonIconName: String {
        if showCheckmark {
            return "checkmark.circle.fill"
        } else if showPlayButton {
            return "play.circle.fill"
        } else {
            return "circle"
        }
    }
    
    var buttonColor: Color {
        if showCheckmark {
            return .green
        } else if showPlayButton {
            return .blue
        } else {
            return .gray
        }
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
                    PianoKeyboardView(
                        highlightedNotes: highlightedNotes,
                        startNote: keyboardStartNote,
                        endNote: keyboardEndNote,
                        scaleFactor: keyboardScaleFactor
                    )
                    .frame(height: 120)
                    .padding(.horizontal, 10)  // Much less padding for wider keyboard
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
                            Image(systemName: buttonIconName)
                                .font(.system(size: 32))
                                .foregroundColor(buttonColor)
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
        } else if showPlayButton {
            // Play audio for current moment
            playMomentAudio()
        }
    }
    
    private func startMoment() {
        guard let moment = currentMoment else { return }
        
        // Clear previous state
        highlightedNotes.removeAll()
        showCheckmark = false
        showPlayButton = true  // Show play button immediately
        isPlayingAudio = false
        
        // Cancel any existing timers
        readingTimer?.invalidate()
        audioTimer?.invalidate()
        
        // Calculate keyboard parameters for this moment
        calculateKeyboardParameters(for: moment)
    }
    
    private func calculateKeyboardParameters(for moment: Moment) {
        // Collect all notes that will be played in this moment
        var allNotes: Set<Int> = []
        for example in moment.audioExamples {
            allNotes.formUnion(example.midiNotes)
        }
        
        guard !allNotes.isEmpty else {
            // No notes, keep default
            keyboardStartNote = 72  // C5
            keyboardEndNote = 84    // C6
            keyboardScaleFactor = 1.0
            return
        }
        
        let lowestNote = allNotes.min()!
        let highestNote = allNotes.max()!
        let range = highestNote - lowestNote + 1
        
        // Default C5-C6 octave range
        let defaultStart = 72
        let defaultEnd = 84
        
        if range <= 12 {
            // Can fit in standard 12-key view
            
            // Check if it fits in default C5-C6 range
            if lowestNote >= defaultStart && highestNote < defaultEnd {
                // Fits in default range, use it
                keyboardStartNote = defaultStart
                keyboardEndNote = defaultEnd
                keyboardScaleFactor = 1.0
            } else {
                // Needs shifting, start from lowest note
                keyboardStartNote = lowestNote
                keyboardEndNote = lowestNote + 12
                keyboardScaleFactor = 1.0
            }
        } else {
            // Needs more than 12 keys - don't scale down, just show more keys
            let keysNeeded = range
            
            if keysNeeded <= 24 {
                // Show all keys, normal size
                keyboardStartNote = lowestNote
                keyboardEndNote = highestNote + 1
                keyboardScaleFactor = 1.0  // Don't scale down
            } else if keysNeeded <= 36 {
                // Show all keys, normal size
                keyboardStartNote = lowestNote
                keyboardEndNote = highestNote + 1
                keyboardScaleFactor = 1.0  // Don't scale down
            } else {
                // Too many keys - show the most important 36
                let center = (lowestNote + highestNote) / 2
                keyboardStartNote = center - 18
                keyboardEndNote = center + 18
                keyboardScaleFactor = 1.0  // Don't scale down
            }
        }
    }
    
    private func playMomentAudio() {
        guard let moment = currentMoment else { return }
        
        isPlayingAudio = true
        showPlayButton = false  // Hide play button while playing
        
        // Play all audio examples in the moment
        var totalDuration: TimeInterval = 0
        
        for example in moment.audioExamples {
            // Don't highlight all notes at once - let playAudioExample handle progressive highlighting
            
            // Play audio (this will handle highlighting)
            playAudioExample(example)
            
            // Calculate actual duration
            if example.isChordProgression {
                // Sum up all chord durations
                if let durations = example.durations {
                    totalDuration += durations.reduce(0, +)
                } else if let chords = example.chords {
                    // Use default duration for each chord
                    totalDuration += Double(chords.count) * example.duration
                }
            } else if example.isSequential {
                if let durations = example.durations {
                    // For ritardando: sum up individual note durations with overlap
                    totalDuration += durations.reduce(0, +) * 0.8
                } else {
                    // Fixed delay between notes
                    let noteDelay = 0.3
                    totalDuration += Double(example.midiNotes.count - 1) * noteDelay + example.duration
                }
            } else {
                // Simultaneous notes: just the duration
                totalDuration += example.duration
            }
        }
        
        // After all audio finishes, clear highlights and show checkmark
        audioTimer = Timer.scheduledTimer(withTimeInterval: totalDuration, repeats: false) { _ in
            isPlayingAudio = false
            highlightedNotes.removeAll() // Clear all highlights when audio completes
            showCheckmark = true
        }
    }
    
    private func playAudioExample(_ example: AudioExample) {
        if example.isChordProgression, let chords = example.chords {
            // Play chord progression
            var delay: TimeInterval = 0
            for (index, chord) in chords.enumerated() {
                // Get duration for this chord
                let chordDuration: TimeInterval
                if let durations = example.durations, index < durations.count {
                    chordDuration = durations[index]
                } else {
                    chordDuration = example.duration
                }
                
                // Schedule this chord
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Clear previous highlights and show only this chord
                    highlightedNotes = Set(chord)
                    
                    // Play all notes in the chord simultaneously
                    for midiNote in chord {
                        soundEngine.playNote(midiNote: midiNote, duration: chordDuration)
                    }
                }
                
                // Add delay for next chord
                delay += chordDuration
            }
        } else if example.isSequential {
            // Play notes in sequence
            if let durations = example.durations {
                // Use individual durations for each note (for ritardando effect)
                var delay: TimeInterval = 0
                for (index, midiNote) in example.midiNotes.enumerated() {
                    let noteDuration = index < durations.count ? durations[index] : example.duration
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // Clear previous highlights and show only this note
                        highlightedNotes = Set([midiNote])
                        soundEngine.playNote(midiNote: midiNote, duration: noteDuration)
                    }
                    
                    delay += noteDuration * 0.8 // Slight overlap for smoother transitions
                }
            } else {
                // Use fixed delay between notes
                let noteDelay = 0.3
                for (index, midiNote) in example.midiNotes.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * noteDelay) {
                        // Clear previous highlights and show only this note
                        highlightedNotes = Set([midiNote])
                        soundEngine.playNote(midiNote: midiNote, duration: example.duration)
                    }
                }
            }
        } else {
            // Play notes simultaneously (chord) - replace all highlights
            highlightedNotes = Set(example.midiNotes)
            for midiNote in example.midiNotes {
                soundEngine.playNote(midiNote: midiNote, duration: example.duration)
            }
        }
    }
    
    private func nextMoment() {
        // Clear highlights
        highlightedNotes.removeAll()
        showCheckmark = false
        showPlayButton = false
        
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