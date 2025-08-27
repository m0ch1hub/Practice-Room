import SwiftUI

// Main view that can replace ChatView for visual music theory lessons
struct MusicTheoryLessonView: View {
    @StateObject private var chatService = ChatService(authService: ServiceAccountAuth())
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var currentSlide = 0
    
    // This would be populated from chatService response in production
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
                // Header
                HStack {
                    Button(action: {}) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Music Theory Lesson")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Slide counter
                    Text("\(currentSlide + 1) / \(slides.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                
                // Main slide content - Locked paging
                TabView(selection: $currentSlide) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slideContent in
                        LessonSlideView(sections: slideContent)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentSlide ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == currentSlide ? 10 : 8,
                                  height: index == currentSlide ? 10 : 8)
                            .animation(.easeInOut, value: currentSlide)
                    }
                }
                .padding(.vertical, 12)
                
                // Bottom control bar
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
        // Send message to generate new lesson slides
        chatService.sendMessage(message)
        // In production, this would parse the response and update slides
    }
}

// Individual Lesson Slide View
struct LessonSlideView: View {
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
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Text content
            ForEach(sections.filter { $0.type == "text" }) { section in
                SlideTextView(content: section.content)
            }
            
            // Piano keyboard visualization
            if !highlightedNotes.isEmpty {
                VStack(spacing: 12) {
                    Text("Piano Keys")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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

#Preview {
    MusicTheoryLessonView()
}