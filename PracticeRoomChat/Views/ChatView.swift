import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {}) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack {
                    Text("ChatGPT")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    // Model selector
                    Picker("Model", selection: $chatService.selectedModel) {
                        ForEach(ChatService.AIModel.allCases, id: \.self) { model in
                            Text(model.displayName)
                                .tag(model)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .scaleEffect(0.8)
                }
                
                Spacer()
                
                Button("Sign up") {
                    // Sign up action
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // Chat content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if chatService.messages.isEmpty {
                            WelcomeView()
                                .padding(.top, 40)
                        }
                        
                        ForEach(chatService.messages) { message in
                            ChatMessageCard(
                                message: message,
                                onPlayExample: playExample
                            )
                            .id(message.id)
                        }
                        
                        if chatService.isLoading {
                            LoadingIndicator()
                        }
                        
                        // Bottom padding for content
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: chatService.messages.count) {
                    withAnimation {
                        proxy.scrollTo(chatService.messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            // Bottom input area
            VStack(spacing: 12) {
                if chatService.messages.isEmpty {
                    SuggestionChips()
                }
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        TextField("Ask anything", text: $messageText)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        if !messageText.isEmpty {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.black)
                                    .clipShape(Circle())
                            }
                            .disabled(chatService.isLoading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.white)
        }
        .background(Color.white)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = messageText
        Logger.shared.ui("Sending message from ChatView: '\(message)'")
        messageText = ""
        chatService.sendMessageWithRAG(message)
    }
    
    private func playExample(_ example: MusicalExample) {
        Logger.shared.ui("Playing example: \(example.type.rawValue) - \(example.content)")
        
        switch example.type {
        case .chordProgression, .sequence:
            let chords = MusicTheory.shared.parseChordProgression(example.content)
            if chords.count > 1 {
                soundEngine.playChordProgression(chords)
            } else if let chord = chords.first {
                soundEngine.playChord(chord)
            }
            
        case .scale:
            // Handle different scale extraction formats
            let cleanContent = example.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = cleanContent.split(separator: " ")
            
            if parts.count >= 2 {
                let root = String(parts[0])
                let type = parts[1...].joined(separator: " ")
                let scale = Scale(root: root, type: type)
                soundEngine.playScale(scale)
            } else if parts.count == 1 {
                // Handle cases like just "C major" where scale was mentioned separately
                let scale = Scale(root: String(parts[0]), type: "major")
                soundEngine.playScale(scale)
            }
            
        case .interval:
            // Handle different interval formats from extraction
            let content = example.content.lowercased()
            
            // Check for named intervals
            if content.contains("major") || content.contains("minor") || content.contains("perfect") {
                // For named intervals, play a reference note and the interval
                let baseNote = Note(name: "C")
                var intervalNote: Note
                
                if content.contains("third") {
                    intervalNote = content.contains("minor") ? 
                        baseNote.transposed(by: 3) : baseNote.transposed(by: 4)
                } else if content.contains("fifth") {
                    intervalNote = baseNote.transposed(by: 7)
                } else if content.contains("second") {
                    intervalNote = content.contains("minor") ? 
                        baseNote.transposed(by: 1) : baseNote.transposed(by: 2)
                } else {
                    intervalNote = baseNote.transposed(by: 4) // Default to major third
                }
                
                soundEngine.playInterval(baseNote, intervalNote, simultaneous: true)
            } else {
                // Handle note-to-note intervals
                let notes = example.content.split(separator: " ").compactMap { part in
                    let cleanPart = String(part).trimmingCharacters(in: CharacterSet.letters.inverted)
                    return cleanPart.count >= 1 ? cleanPart : nil
                }
                
                if notes.count >= 2 {
                    let note1 = Note(name: notes[0])
                    let note2 = Note(name: notes[1])
                    soundEngine.playInterval(note1, note2, simultaneous: true)
                }
            }
            
        case .note:
            let note = Note(name: example.content)
            soundEngine.playNote(note)
            
        case .chord:
            if let chord = MusicTheory.shared.parseChordProgression(example.content).first {
                soundEngine.playChord(chord)
            }
        }
    }
}

struct ChatMessageCard: View {
    let message: ChatMessage
    let onPlayExample: (MusicalExample) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.role == "user" {
                // User message - no background, just text
                VStack(alignment: .leading, spacing: 12) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Assistant response - no background, just text
                VStack(alignment: .leading, spacing: 16) {
                    FormattedText(content: message.content)
                    
                    // Audio examples are now handled inline via FormattedText
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct PlayButton: View {
    let example: MusicalExample
    let onPlay: (MusicalExample) -> Void
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            isPlaying = true
            Logger.shared.ui("Play button tapped for: \(example.displayText)")
            onPlay(example)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPlaying = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "speaker.wave.3.fill" : "play.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(example.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .scaleEffect(isPlaying ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}

struct SuggestionChips: View {
    let suggestions = [
        "What is a major chord?\nLearn the basics of chord construction",
        "Explain the ii-V-I progression\nto understand jazz harmony"
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {
                    // Handle suggestion tap
                }) {
                    VStack(alignment: .leading) {
                        let lines = suggestion.components(separatedBy: "\n")
                        if lines.count > 1 {
                            Text(lines[0])
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Text(lines[1])
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        } else {
                            Text(suggestion)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

struct LoadingIndicator: View {
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: UUID()
                        )
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
    }
}

struct FormattedText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseSections(), id: \.id) { section in
                section.view
            }
        }
    }
    
    private func parseSections() -> [FormattedSection] {
        let lines = content.components(separatedBy: .newlines)
        var sections: [FormattedSection] = []
        var currentParagraph: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                // Empty line - finish current paragraph if it exists
                if !currentParagraph.isEmpty {
                    sections.append(FormattedSection(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " "),
                        id: UUID()
                    ))
                    currentParagraph = []
                }
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && trimmed.count > 4 {
                // Bold heading
                if !currentParagraph.isEmpty {
                    sections.append(FormattedSection(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " "),
                        id: UUID()
                    ))
                    currentParagraph = []
                }
                let title = String(trimmed.dropFirst(2).dropLast(2))
                sections.append(FormattedSection(
                    type: .title,
                    content: title,
                    id: UUID()
                ))
            } else if trimmed.range(of: #"^(\d+)\.\s+"#, options: .regularExpression) != nil {
                // Numbered list item
                if !currentParagraph.isEmpty {
                    sections.append(FormattedSection(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " "),
                        id: UUID()
                    ))
                    currentParagraph = []
                }
                sections.append(FormattedSection(
                    type: .numberedItem,
                    content: trimmed,
                    id: UUID()
                ))
            } else if trimmed.hasPrefix("• ") || trimmed.hasPrefix("- ") {
                // Bullet point
                if !currentParagraph.isEmpty {
                    sections.append(FormattedSection(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " "),
                        id: UUID()
                    ))
                    currentParagraph = []
                }
                let content = String(trimmed.dropFirst(2))
                sections.append(FormattedSection(
                    type: .bulletItem,
                    content: content,
                    id: UUID()
                ))
            } else if trimmed.hasPrefix("[AUDIO:") && trimmed.hasSuffix("]") {
                // Audio marker
                if !currentParagraph.isEmpty {
                    sections.append(FormattedSection(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " "),
                        id: UUID()
                    ))
                    currentParagraph = []
                }
                sections.append(FormattedSection(
                    type: .audio,
                    content: trimmed,
                    id: UUID()
                ))
            } else {
                // Regular paragraph text
                currentParagraph.append(trimmed)
            }
        }
        
        // Handle remaining paragraph
        if !currentParagraph.isEmpty {
            sections.append(FormattedSection(
                type: .paragraph,
                content: currentParagraph.joined(separator: " "),
                id: UUID()
            ))
        }
        
        return sections
    }
}

struct FormattedSection {
    enum SectionType {
        case title
        case paragraph
        case numberedItem
        case bulletItem
        case audio
    }
    
    let type: SectionType
    let content: String
    let id: UUID
    
    var view: some View {
        Group {
            switch type {
            case .title:
                Text(content)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    .fixedSize(horizontal: false, vertical: true)
                
            case .paragraph:
                formatInlineText(content)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
            case .numberedItem:
                HStack(alignment: .top, spacing: 12) {
                    Text(extractNumberFromContent(content))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 16, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        formatInlineText(removeNumberFromContent(content))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
                
            case .bulletItem:
                HStack(alignment: .top, spacing: 12) {
                    Text("•")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 16, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        formatInlineText(content)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 2)
                
            case .audio:
                // Parse audio marker and create inline button
                if let audioExample = parseAudioMarker(content) {
                    InlineAudioButton(example: audioExample)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func extractNumberFromContent(_ content: String) -> String {
        if let match = content.range(of: #"^(\d+)\."#, options: .regularExpression) {
            return String(content[match])
        }
        return "1."
    }
    
    private func removeNumberFromContent(_ content: String) -> String {
        if let match = content.range(of: #"^(\d+)\.\s*"#, options: .regularExpression) {
            return String(content[match.upperBound...])
        }
        return content
    }
    
    private func formatInlineText(_ text: String) -> Text {
        let parts = text.components(separatedBy: "**")
        var textViews: [Text] = []
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 0 {
                // Regular text
                if !part.isEmpty {
                    textViews.append(Text(part).font(.system(size: 16)))
                }
            } else {
                // Bold text
                if !part.isEmpty {
                    textViews.append(Text(part).font(.system(size: 16, weight: .semibold)))
                }
            }
        }
        
        return textViews.reduce(Text(""), +)
    }
    
    private func parseAudioMarker(_ marker: String) -> MusicalExample? {
        // Parse [AUDIO:MIDI:60:1.0s:Play Root Note (C)]
        let pattern = "\\[AUDIO:MIDI:([^:]+):([^:]+):([^\\]]+)\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(marker.startIndex..<marker.endIndex, in: marker)
        
        if let match = regex.firstMatch(in: marker, options: [], range: range),
           let midiNotesRange = Range(match.range(at: 1), in: marker),
           let durationRange = Range(match.range(at: 2), in: marker),
           let displayRange = Range(match.range(at: 3), in: marker) {
            
            let midiNotes = String(marker[midiNotesRange])
            let duration = String(marker[durationRange])
            let displayText = String(marker[displayRange])
            
            let content = "MIDI:\(midiNotes):\(duration)"
            
            // Determine type from MIDI content
            let exampleType: MusicalExample.ExampleType
            if midiNotes.contains(",") {
                if midiNotes.components(separatedBy: ",").count > 2 {
                    exampleType = .chord
                } else {
                    exampleType = .interval
                }
            } else {
                exampleType = .note
            }
            
            return MusicalExample(
                type: exampleType,
                content: content,
                displayText: displayText
            )
        }
        
        return nil
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Music Theory Chat")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Ask me about chords, scales, intervals, or any music theory concept. I can play examples to help you understand better.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 60)
    }
}

struct InlineAudioButton: View {
    let example: MusicalExample
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            playAudio()
        }) {
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "speaker.wave.2" : "play.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text(example.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPlaying ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
    
    private func playAudio() {
        isPlaying = true
        
        // Use the same audio playing logic as the main PlayButton
        Logger.shared.ui("Inline play button tapped for: \(example.displayText)")
        Logger.shared.ui("Playing example: \(example.type) - \(example.content)")
        
        let soundEngine = SoundEngine.shared
        
        switch example.type {
        case .interval:
            if example.content.hasPrefix("MIDI:") {
                // Handle MIDI format: MIDI:60,64:1.5s
                let midiContent = String(example.content.dropFirst(5)) // Remove "MIDI:"
                let components = midiContent.components(separatedBy: ":")
                if let notesStr = components.first {
                    let noteNumbers = notesStr.components(separatedBy: ",").compactMap { Int($0) }
                    if noteNumbers.count >= 2 {
                        let note1 = createNoteFromMIDI(noteNumbers[0])
                        let note2 = createNoteFromMIDI(noteNumbers[1])
                        soundEngine.playInterval(note1, note2, simultaneous: true)
                    }
                }
            }
            
        case .note:
            if example.content.hasPrefix("MIDI:") {
                let midiContent = String(example.content.dropFirst(5)) // Remove "MIDI:"
                let components = midiContent.components(separatedBy: ":")
                if let noteStr = components.first,
                   let noteNumber = Int(noteStr) {
                    let note = createNoteFromMIDI(noteNumber)
                    soundEngine.playNote(note)
                }
            }
            
        case .chord:
            if let chord = MusicTheory.shared.parseChordProgression(example.content).first {
                soundEngine.playChord(chord)
            }
        
        default:
            break
        }
        
        // Reset playing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPlaying = false
        }
    }
    
    private func createNoteFromMIDI(_ midiNumber: Int) -> Note {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let pitchClass = midiNumber % 12
        let octave = midiNumber / 12 - 1
        return Note(name: noteNames[pitchClass], octave: octave)
    }
}