import SwiftUI
import AVFoundation

struct MusicLessonSlidesView: View {
    let sections: [LessonSection]
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isAutoPlaying = false
    @State private var autoPlayTimer: Timer?
    
    init(jsonContent: String) {
        self.sections = LessonSection.parse(from: jsonContent)
    }
    
    // For preview/testing
    init(sections: [LessonSection]) {
        self.sections = sections
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<sections.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.blue : Color(.systemGray4))
                                .frame(width: index == currentIndex ? 8 : 6, 
                                      height: index == currentIndex ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: toggleAutoPlay) {
                        Image(systemName: isAutoPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Main content area with slides
                GeometryReader { geometry in
                    TabView(selection: $currentIndex) {
                        ForEach(sections.indices, id: \.self) { index in
                            SlideView(
                                section: sections[index],
                                onPlayAudio: playAudio
                            )
                            .tag(index)
                            .frame(width: geometry.size.width)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _ in
                        // Auto-play audio when slide changes
                        if sections[currentIndex].hasAudio {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                playAudio(sections[currentIndex].audioContent ?? "")
                            }
                        }
                    }
                }
                
                // Bottom navigation
                HStack(spacing: 30) {
                    Button(action: previousSlide) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(currentIndex > 0 ? .primary : .gray)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentIndex == 0)
                    
                    // Piano keyboard visualization (when applicable)
                    if sections[currentIndex].hasKeyboard {
                        MiniKeyboardView(
                            highlightedNotes: sections[currentIndex].highlightedNotes
                        )
                        .frame(height: 60)
                    } else {
                        Spacer().frame(height: 60)
                    }
                    
                    Button(action: nextSlide) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(currentIndex < sections.count - 1 ? .primary : .gray)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentIndex == sections.count - 1)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func nextSlide() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if currentIndex < sections.count - 1 {
                currentIndex += 1
            }
        }
    }
    
    private func previousSlide() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if currentIndex > 0 {
                currentIndex -= 1
            }
        }
    }
    
    private func toggleAutoPlay() {
        isAutoPlaying.toggle()
        
        if isAutoPlaying {
            startAutoPlay()
        } else {
            autoPlayTimer?.invalidate()
            autoPlayTimer = nil
        }
    }
    
    private func startAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            if currentIndex < sections.count - 1 {
                nextSlide()
            } else {
                isAutoPlaying = false
                autoPlayTimer?.invalidate()
            }
        }
    }
    
    private func playAudio(_ content: String) {
        // Parse MIDI format: "MIDI:60,64,67:2.0s"
        if content.hasPrefix("MIDI:") {
            let components = content.dropFirst(5).components(separatedBy: ":")
            guard components.count >= 2 else { return }
            
            let noteString = components[0]
            let notes = noteString.components(separatedBy: ",").compactMap { Int($0) }
            
            if notes.count == 1 {
                let note = createNoteFromMIDI(notes[0])
                soundEngine.playNote(note)
            } else if notes.count == 2 {
                let note1 = createNoteFromMIDI(notes[0])
                let note2 = createNoteFromMIDI(notes[1])
                soundEngine.playInterval(note1, note2, simultaneous: true)
            } else if notes.count >= 3 {
                let rootNote = createNoteFromMIDI(notes[0])
                let chord = Chord(root: rootNote.name, quality: "major")
                soundEngine.playChord(chord)
            }
        }
    }
    
    private func createNoteFromMIDI(_ midiNumber: Int) -> Note {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let pitchClass = midiNumber % 12
        let octave = midiNumber / 12 - 1
        return Note(name: noteNames[pitchClass], octave: octave)
    }
}

struct SlideView: View {
    let section: LessonSection
    let onPlayAudio: (String) -> Void
    @State private var hasPlayedAudio = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            if let title = section.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Main content
            Text(section.content)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Audio play button (if applicable)
            if section.hasAudio, let displayText = section.displayText {
                Button(action: {
                    onPlayAudio(section.audioContent ?? "")
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                        Text(displayText)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
            }
            
            Spacer()
        }
        .onAppear {
            // Auto-play audio when slide appears (with slight delay)
            if section.hasAudio && !hasPlayedAudio {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onPlayAudio(section.audioContent ?? "")
                    hasPlayedAudio = true
                }
            }
        }
    }
}

struct MiniKeyboardView: View {
    let highlightedNotes: Set<Int>
    
    private let whiteKeys = [0, 2, 4, 5, 7, 9, 11] // C, D, E, F, G, A, B
    private let blackKeys = [1, 3, 6, 8, 10] // C#, D#, F#, G#, A#
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // White keys
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { index in
                        let noteNumber = 60 + whiteKeys[index] // Starting from C4
                        Rectangle()
                            .fill(highlightedNotes.contains(noteNumber) ? Color.blue : Color.white)
                            .border(Color.gray, width: 1)
                            .frame(width: geometry.size.width / 7 - 2)
                    }
                }
                
                // Black keys
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        if index != 2 && index != 6 { // No black key between E-F and B-C
                            let noteNumber = 60 + (index < 2 ? blackKeys[index] : blackKeys[index - 1])
                            Rectangle()
                                .fill(highlightedNotes.contains(noteNumber) ? Color.blue.opacity(0.8) : Color.black)
                                .frame(width: geometry.size.width / 10, height: geometry.size.height * 0.6)
                                .offset(x: CGFloat(index) * (geometry.size.width / 7))
                        }
                    }
                }
            }
        }
    }
}

// Data model for lesson sections
struct LessonSection: Identifiable {
    let id = UUID()
    let type: SectionType
    let title: String?
    let content: String
    let audioContent: String?
    let displayText: String?
    
    enum SectionType {
        case text
        case audio
    }
    
    var hasAudio: Bool {
        audioContent != nil
    }
    
    var hasKeyboard: Bool {
        // Show keyboard for audio sections
        hasAudio
    }
    
    var highlightedNotes: Set<Int> {
        // Parse MIDI notes from audio content
        guard let audio = audioContent, audio.hasPrefix("MIDI:") else { return [] }
        let components = audio.dropFirst(5).components(separatedBy: ":")
        guard let noteString = components.first else { return [] }
        let notes = noteString.components(separatedBy: ",").compactMap { Int($0) }
        return Set(notes)
    }
    
    // Parse sections from JSON response
    static func parse(from jsonContent: String) -> [LessonSection] {
        // Parse the actual JSON response from the API
        var sections: [LessonSection] = []
        
        guard let jsonData = jsonContent.data(using: .utf8),
              let jsonResponse = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let sectionsArray = jsonResponse["sections"] as? [[String: Any]] else {
            // Return empty if parsing fails
            return []
        }
        
        for section in sectionsArray {
            guard let type = section["type"] as? String,
                  let content = section["content"] as? String else {
                continue
            }
            
            if type == "text" {
                // Extract title from bold text if present
                let title = extractTitle(from: content)
                let cleanContent = removeTitle(from: content)
                
                sections.append(LessonSection(
                    type: .text,
                    title: title,
                    content: cleanContent,
                    audioContent: nil,
                    displayText: nil
                ))
            } else if type == "audio" {
                // Use previous section's title if it was text
                let title = sections.last?.title
                let audioContent = section["content"] as? String
                let displayText = section["displayText"] as? String
                
                sections.append(LessonSection(
                    type: .audio,
                    title: title,
                    content: "", // Audio sections don't need text content
                    audioContent: audioContent,
                    displayText: displayText
                ))
            }
        }
        
        return sections
    }
    
    private static func extractTitle(from content: String) -> String? {
        // Look for bold text that could be a title
        let pattern = "\\*\\*(.+?)\\*\\*"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range),
           let titleRange = Range(match.range(at: 1), in: content) {
            return String(content[titleRange])
        }
        
        return nil
    }
    
    private static func removeTitle(from content: String) -> String {
        // Remove the first bold text (title) from content
        let pattern = "\\*\\*(.+?)\\*\\*\\n?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range) {
            var cleanContent = content
            if let matchRange = Range(match.range(at: 0), in: content) {
                cleanContent.removeSubrange(matchRange)
            }
            return cleanContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return content
    }
}

#Preview {
    MusicLessonSlidesView(sections: [
        LessonSection(
            type: .text,
            title: "What is a Major Chord?",
            content: "A major chord consists of three notes. Let's explore how it's built.",
            audioContent: nil,
            displayText: nil
        ),
        LessonSection(
            type: .audio,
            title: "The Root Note",
            content: "First, we have our root note, which in this case is C.",
            audioContent: "MIDI:60:1.0s",
            displayText: "Play Root Note (C)"
        )
    ])
}