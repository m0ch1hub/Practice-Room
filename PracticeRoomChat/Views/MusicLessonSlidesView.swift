import SwiftUI
import AVFoundation

struct MusicLessonSlidesView: View {
    @StateObject private var soundEngine = SoundEngine.shared
    @StateObject private var chatService = ChatService(authService: ServiceAccountAuth())
    @State private var currentSlide = 0
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Binding var isPresented: Bool
    
    // Fake JSON response with slide structure
    let slides: [[SlideSection]] = [
        [
            SlideSection(
                type: "text",
                slide: 1,
                content: "**What is a Major Chord?**\n\nA major chord consists of three notes. Let's build one together step by step."
            )
        ],
        [
            SlideSection(
                type: "text", 
                slide: 2,
                content: "**1. The Root Note**\nFirst, we start with our foundation - the root note. In this example, we'll use C."
            ),
            SlideSection(
                type: "audio",
                slide: 2,
                content: "MIDI:60:1.0s",
                displayText: "Play Root Note (C)"
            )
        ],
        [
            SlideSection(
                type: "text",
                slide: 3,
                content: "**2. The Major Third**\nNext, we add the major third - exactly four half steps above our root note."
            ),
            SlideSection(
                type: "audio",
                slide: 3,
                content: "MIDI:60,64:1.5s",
                displayText: "Play Major Third (C-E)"
            )
        ],
        [
            SlideSection(
                type: "text",
                slide: 4,
                content: "**3. The Perfect Fifth**\nFinally, we complete the chord with the perfect fifth - seven half steps from the root."
            ),
            SlideSection(
                type: "audio",
                slide: 4,
                content: "MIDI:60,67:1.5s",
                displayText: "Play Perfect Fifth (C-G)"
            )
        ],
        [
            SlideSection(
                type: "text",
                slide: 5,
                content: "**The Complete C Major Chord**\nAll three notes together create that bright, stable major sound!"
            ),
            SlideSection(
                type: "audio",
                slide: 5,
                content: "MIDI:60,64,67:2.0s",
                displayText: "Play Complete C Major"
            )
        ]
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header similar to ChatView
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
                    
                    // Empty space to balance the header
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                
                // Main slide content - Vertical scrolling with visible adjacent slides
                GeometryReader { geometry in
                    ScrollViewReader { scrollProxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Add padding at the top
                                Color.clear
                                    .frame(height: geometry.size.height * 0.25)
                                
                                ForEach(Array(slides.enumerated()), id: \.offset) { index, slideContent in
                                    VStack(spacing: 0) {
                                        SlideContentView(sections: slideContent)
                                            .frame(height: geometry.size.height * 0.7)
                                            .frame(maxWidth: .infinity)
                                            .padding(.horizontal, 20)
                                        
                                        // Separator line between slides
                                        if index < slides.count - 1 {
                                            Rectangle()
                                                .fill(Color(.separator))
                                                .frame(height: 0.5)
                                                .padding(.horizontal, 40)
                                                .padding(.vertical, 20)
                                        }
                                    }
                                    .id(index)
                                }
                                
                                // Add padding at the bottom
                                Color.clear
                                    .frame(height: geometry.size.height * 0.25)
                            }
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollTargetLayout()
                        .onAppear {
                            // Start at first slide
                            scrollProxy.scrollTo(0, anchor: .center)
                        }
                    }
                }
                
                // Bottom control bar from ChatView
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        TextField("Ask a question", text: $messageText)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        if !messageText.isEmpty {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.blue)
                            }
                            .disabled(chatService.isLoading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = messageText
        messageText = ""
        // For now, just log - in production, this would generate new slides
        Logger.shared.ui("Slide view question: '\(message)'")
        // Could transition back to chat or generate new slides here
        chatService.sendMessage(message)
        isPresented = false // Return to chat view to see response
    }
}

// Slide Section Model
struct SlideSection: Identifiable {
    let id = UUID()
    let type: String
    let slide: Int
    let content: String
    let displayText: String?
    
    init(type: String, slide: Int, content: String, displayText: String? = nil) {
        self.type = type
        self.slide = slide
        self.content = content
        self.displayText = displayText
    }
}

// Individual Slide Content View
struct SlideContentView: View {
    let sections: [SlideSection]
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var isPlaying = false
    
    // Extract MIDI notes from audio sections
    private var highlightedNotes: Set<Int> {
        var notes = Set<Int>()
        for section in sections where section.type == "audio" {
            if section.content.starts(with: "MIDI:") {
                let parts = section.content.dropFirst(5).split(separator: ":")
                if let noteString = parts.first {
                    let midiNotes = String(noteString).split(separator: ",").compactMap { Int($0) }
                    notes.formUnion(midiNotes)
                }
            }
        }
        return notes
    }

    // If a slide contains an audio section with exactly two notes, we expose
    // that pair so we can render an IntervalBridge overlay above the keyboard.
    // This keeps the visual tightly coupled to the data coming from a lesson
    // slide, while staying decoupled from the keyboard implementation details.
    private var intervalPair: (Int, Int)? {
        for section in sections where section.type == "audio" {
            guard section.content.starts(with: "MIDI:") else { continue }
            let parts = section.content.dropFirst(5).split(separator: ":")
            if let noteString = parts.first {
                let notes = String(noteString).split(separator: ",").compactMap { Int($0) }
                if notes.count == 2 {
                    return (notes[0], notes[1])
                }
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Text content
            ForEach(sections.filter { $0.type == "text" }) { section in
                SlideTextView(content: section.content)
            }
            
            // Piano keyboard visualization
            if !highlightedNotes.isEmpty {
                VStack(spacing: 8) {
                    // Place the interval bridge ABOVE the keyboard for better
                    // readability and to avoid overlapping the key caps.
                    if let pair = intervalPair {
                        IntervalBridgeView(startMidi: pair.0, endMidi: pair.1)
                            .frame(height: 44)
                            .padding(.horizontal, 40)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    PianoKeyboardView(highlightedNotes: highlightedNotes)
                        .frame(height: 120)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
            }
            
            // Audio controls
            ForEach(sections.filter { $0.type == "audio" }) { section in
                AudioPlayButton(
                    content: section.content,
                    displayText: section.displayText ?? "Play"
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// Text component for slides
struct SlideTextView: View {
    let content: String
    
    var body: some View {
        let parts = content.components(separatedBy: "**")
        
        VStack(spacing: 15) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index % 2 == 1 {
                    // Bold text
                    Text(part)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                } else if !part.isEmpty {
                    // Regular text
                    Text(part.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// Audio play button component
struct AudioPlayButton: View {
    let content: String
    let displayText: String
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: playAudio) {
            HStack(spacing: 15) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                
                Text(displayText)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 10)
        }
        .scaleEffect(isPlaying ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isPlaying)
    }
    
    func playAudio() {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        // Parse MIDI content and play
        if content.starts(with: "MIDI:") {
            let parts = content.dropFirst(5).split(separator: ":")
            if parts.count >= 2 {
                let notes = String(parts[0]).split(separator: ",").compactMap { Int($0) }
                
                if notes.count == 1 {
                    soundEngine.playNote(midiNote: notes[0], duration: 0.5)
                } else if notes.count > 1 {
                    soundEngine.playChord(midiNotes: notes, duration: 2.0)
                }
            }
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isPlaying = false
        }
    }
}

// Enhanced Piano Keyboard View
struct PianoKeyboardView: View {
    let highlightedNotes: Set<Int>
    
    private let whiteKeyPositions = [0, 2, 4, 5, 7, 9, 11] // C, D, E, F, G, A, B
    // Black keys mapped to the white-key boundary they sit over (1-based)
    private let blackKeyBoundaries: [(note: Int, boundary: Int)] = [
        (1, 1),  // C# between C and D
        (3, 2),  // D# between D and E
        (6, 4),  // F# between F and G
        (8, 5),  // G# between G and A
        (10, 6)  // A# between A and B
    ]
    
    var body: some View {
        GeometryReader { geometry in
            // Equal white keys without gaps; black keys ~60% width, centered on boundaries
            let whiteKeyWidth = geometry.size.width / 7
            let blackKeyWidth = whiteKeyWidth * 0.6
            
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        let noteNumber = 60 + whiteKeyPositions[index]
                        let isHighlighted = highlightedNotes.contains(noteNumber)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isHighlighted ? 
                                  LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue],
                                               startPoint: .top, endPoint: .bottom) :
                                  LinearGradient(colors: [Color.white, Color(.systemGray6)],
                                               startPoint: .top, endPoint: .bottom))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(.systemGray3), lineWidth: 0.5)
                            )
                            .shadow(color: isHighlighted ? .blue.opacity(0.5) : .black.opacity(0.1), 
                                   radius: isHighlighted ? 8 : 2, y: 2)
                            .frame(width: whiteKeyWidth)
                    }
                }
                
                // Black keys - positioned centered between white keys  
                ForEach(blackKeyBoundaries, id: \.note) { key in
                    let noteNumber = 60 + key.note
                    let isHighlighted = highlightedNotes.contains(noteNumber)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isHighlighted ?
                              LinearGradient(colors: [Color.blue, Color.blue.opacity(0.6)],
                                           startPoint: .top, endPoint: .bottom) :
                              LinearGradient(colors: [Color.black, Color(.systemGray2)],
                                           startPoint: .top, endPoint: .bottom))
                        .frame(width: blackKeyWidth, height: geometry.size.height * 0.6)
                        .offset(x: (CGFloat(key.boundary) * whiteKeyWidth) - (blackKeyWidth / 2))
                        .shadow(color: isHighlighted ? .blue.opacity(0.6) : .black.opacity(0.3), 
                               radius: isHighlighted ? 2 : 1, y: 1)
                }
            }
        }
    }
}

// Interval Bridge Overlay
// -----------------------
// Draws a small arc above the keyboard that spans between two MIDI notes.
// The arc's height and color encode the interval size (in semitones) so the
// relationship is immediately legible at a glance. This view purposefully does
// not try to know anything about keyboard drawing; instead it mirrors the
// spacing logic used by PianoKeyboardView (7 equal white keys, black keys on
// boundaries) to compute x-positions.
struct IntervalBridgeView: View {
    let startMidi: Int
    let endMidi: Int
    
    private var semitoneDistance: Int {
        abs(endMidi - startMidi)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let x1 = xPosition(for: startMidi, totalWidth: width)
            let x2 = xPosition(for: endMidi, totalWidth: width)
            let minX = min(x1, x2)
            let maxX = max(x1, x2)
            let color = colorForSemitones(semitoneDistance)
            let label = intervalName(for: semitoneDistance)
            let tickHeight = arcHeightForSemitones(semitoneDistance, totalWidth: width)
            
            ZStack(alignment: .topLeading) {
                // Simple black bracket with small vertical ticks: ┌────┐
                IntervalBracket(startX: minX, endX: maxX, tickHeight: tickHeight)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .padding(.top, 0)

                // Minimal, centered label with interval name only
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .position(x: (minX + maxX) / 2, y: 6)
                    .accessibilityLabel("Interval: \(label)")
            }
        }
    }
    
    // MARK: - Layout helpers
    
    // Mirrors the spacing used by PianoKeyboardView: 7 equal white keys across
    // the width. White key centers are at .5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5
    // multiples of a white key's width. Black keys sit on whole-number
    // boundaries between white keys.
    private func xPosition(for midi: Int, totalWidth: CGFloat) -> CGFloat {
        let stepMap: [Int: CGFloat] = [
            0: 0.5, // C
            1: 1.0, // C# boundary
            2: 1.5, // D
            3: 2.0, // D# boundary
            4: 2.5, // E
            5: 3.5, // F
            6: 4.0, // F# boundary
            7: 4.5, // G
            8: 5.0, // G# boundary
            9: 5.5, // A
            10: 6.0, // A# boundary
            11: 6.5  // B
        ]
        let noteClass = midi % 12
        let step = stepMap[noteClass] ?? 0.5
        let whiteKeyWidth = totalWidth / 7
        return step * whiteKeyWidth
    }
    
    private func colorForSemitones(_ n: Int) -> Color { .black }
    
    private func intervalName(for n: Int) -> String {
        switch n {
        case 0: return "Unison"
        case 1: return "Minor second"
        case 2: return "Major second"
        case 3: return "Minor third"
        case 4: return "Major third"
        case 5: return "Perfect fourth"
        case 6: return "Tritone"
        case 7: return "Perfect fifth"
        case 8: return "Minor sixth"
        case 9: return "Major sixth"
        case 10: return "Minor seventh"
        case 11: return "Major seventh"
        case 12: return "Octave"
        default: return "Interval"
        }
    }
    
    private func arcHeightForSemitones(_ n: Int, totalWidth: CGFloat) -> CGFloat {
        // Height here is used as the bracket tick length. Keep it compact.
        let base: CGFloat = 8
        let perStep: CGFloat = 1.2
        let maxHeight: CGFloat = 16
        return min(base + CGFloat(min(n, 9)) * perStep, maxHeight)
    }
}

// Simple bracket used by IntervalBridgeView: a straight line with short
// vertical ticks at both ends. Intentionally minimal and black.
struct IntervalBracket: Shape {
    let startX: CGFloat
    let endX: CGFloat
    let tickHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y: CGFloat = 18
        let xMin = min(startX, endX)
        let xMax = max(startX, endX)
        
        // Left tick
        p.move(to: CGPoint(x: xMin, y: y))
        p.addLine(to: CGPoint(x: xMin, y: y + tickHeight))
        
        // Horizontal span
        p.move(to: CGPoint(x: xMin, y: y))
        p.addLine(to: CGPoint(x: xMax, y: y))
        
        // Right tick
        p.move(to: CGPoint(x: xMax, y: y))
        p.addLine(to: CGPoint(x: xMax, y: y + tickHeight))
        
        return p
    }
}

// Placeholder SlideView for backward compatibility
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
    MusicLessonSlidesView(isPresented: .constant(true))
}