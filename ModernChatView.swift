import SwiftUI

/// Modern ChatView using official Liquid Glass design system
/// Built for current iOS with forward compatibility
struct ModernChatView: View {
    @StateObject private var chatService = ChatService(authService: ServiceAccountAuth())
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingExamplesMenu = false
    @State private var detailedQuestions: [String] = []
    @State private var simpleQuestions: [String] = []
    @State private var showingSettings = false
    @AppStorage("notationDisplay") private var notationDisplay = NotationDisplay.keyboard.rawValue
    // Using native iOS 26 menu instead of sheet
    
    @Namespace private var mainGlassNamespace
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            backgroundView
            
            // Main content in glass container
            GlassEffectContainer(spacing: 20.0) {
                VStack(spacing: 0) {
                    // Modern Glass Header
                    ModernGlassHeader(
                        title: "Practice Room Chat",
                        onMenuTap: { /* Handle menu */ },
                        onSettingsTap: { showingSettings = true }
                    )
                    .glassEffectID("header", in: mainGlassNamespace)
                    
                    // Chat Content
                    chatContentView
                    
                    // Bottom Controls
                    bottomControlsView
                }
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        isTextFieldFocused = false
                    }
                }
        )
        .onAppear {
            loadAvailableQuestions()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        // Using native iOS 26 menu instead of sheet
    }
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var chatContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    Color.clear.frame(height: 20) // Top padding
                    
                    if chatService.messages.isEmpty {
                        ModernWelcomeView()
                            .padding(.top, 40)
                    }
                    
                    ForEach(chatService.messages) { message in
                        ModernChatMessageView(
                            message: message,
                            scrollProxy: proxy
                        )
                        .id(message.id)
                    }
                    
                    if chatService.isLoading {
                        ModernLoadingIndicator()
                            .id("loading")
                    }
                    
                    Color.clear
                        .frame(height: 300) // Bottom padding for keyboard
                        .id("bottom")
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: chatService.messages.count) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    private var bottomControlsView: some View {
        VStack(spacing: 16) {
            // Notation Display with Glass Effect
            notationDisplayView
                .glassEffectID("notation", in: mainGlassNamespace)
            
            // Suggestion Chips (only when no messages)
            if chatService.messages.isEmpty {
                ModernGlassSuggestionChips(
                    suggestions: ["What is a major chord?", "Show me the C major scale"],
                    onSuggestionTap: { suggestion in
                        chatService.sendMessage(suggestion)
                    }
                )
                .glassEffectID("suggestions", in: mainGlassNamespace)
            }
            
            // Modern Control Bar with native iOS 26 menu
            HStack(alignment: .bottom, spacing: 16) {
                // Native Menu button
                Menu {
                    if !detailedQuestions.isEmpty {
                        Section("Questions") {
                            ForEach(detailedQuestions, id: \.self) { question in
                                Button(action: {
                                    messageText = question
                                    sendMessage()
                                }) {
                                    Label(question, systemImage: "questionmark.circle")
                                }
                            }
                        }
                    }

                    if !simpleQuestions.isEmpty {
                        Section("Commands") {
                            ForEach(simpleQuestions, id: \.self) { question in
                                Button(action: {
                                    messageText = question
                                    sendMessage()
                                }) {
                                    Label(question, systemImage: "play.circle")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.glass)

                // Input field
                ModernLiquidGlassControlBar(
                    messageText: $messageText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: sendMessage,
                    onMenuTap: {} // Not needed anymore
                )
            }
            .padding(.horizontal, 16)
            .glassEffectID("controlBar", in: mainGlassNamespace)
        }
        .padding(.bottom, 8)
    }
    
    private var notationDisplayView: some View {
        Group {
            switch NotationDisplay(rawValue: notationDisplay) ?? .keyboard {
            case .keyboard:
                ModernGlassMidiKeyboard(
                    midiNotes: Array(soundEngine.currentlyPlayingNotes),
                    showLabels: true,
                    minNote: soundEngine.keyboardRange.minNote,
                    maxNote: soundEngine.keyboardRange.maxNote
                )
                .frame(height: 180)
                .frame(maxWidth: 300)

            case .staff:
                StaffNotationView(
                    midiNotes: Array(soundEngine.currentlyPlayingNotes),
                    showLabels: true,
                    minNote: soundEngine.keyboardRange.minNote,
                    maxNote: soundEngine.keyboardRange.maxNote
                )
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.interactive(false), in: .rect(cornerRadius: 12))

            case .both:
                VStack(spacing: 8) {
                    StaffNotationView(
                        midiNotes: Array(soundEngine.currentlyPlayingNotes),
                        showLabels: false,
                        minNote: soundEngine.keyboardRange.minNote,
                        maxNote: soundEngine.keyboardRange.maxNote
                    )
                    .frame(height: 85)
                    .glassEffect(.regular, in: .rect(cornerRadius: 8))

                    ModernGlassMidiKeyboard(
                        midiNotes: Array(soundEngine.currentlyPlayingNotes),
                        showLabels: true,
                        minNote: soundEngine.keyboardRange.minNote,
                        maxNote: soundEngine.keyboardRange.maxNote
                    )
                    .frame(height: 85)
                    .frame(maxWidth: 300)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func loadAvailableQuestions() {
        let examples = TrainingDataManager.shared.loadMainQuestions()
        let allQuestions = examples.compactMap { example in
            example.contents.first(where: { $0.role == "user" })?.parts.first?.text
        }
        
        detailedQuestions = allQuestions.filter { $0.lowercased().starts(with: "what") }
        simpleQuestions = allQuestions.filter { $0.lowercased().starts(with: "play") }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let message = messageText
        Logger.shared.ui("Sending message from ModernChatView: '\(message)'")
        messageText = ""
        isTextFieldFocused = false
        chatService.sendMessage(message)
    }
}

// MARK: - Modern Supporting Views

struct ModernChatMessageView: View {
    let message: ChatMessage
    let scrollProxy: ScrollViewProxy
    @Namespace private var messageNamespace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.role == "user" {
                ModernGlassMessageBubble(
                    message: message.content,
                    isUser: true
                )
            } else {
                // Assistant response with glass effect
                ProgressiveResponseView(
                    response: ProgressiveResponse.parse(message.content),
                    scrollProxy: scrollProxy,
                    messageId: message.id
                )
                .glassEffect(
                    .regular.tint(.clear).interactive(false),
                    in: .rect(cornerRadius: 16)
                )
                .padding(.vertical, 8)
            }
        }
    }
}

struct ModernLoadingIndicator: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(
                            1.0 + 0.3 * sin(animationPhase + Double(index) * 0.8)
                        )
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            
            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

struct ModernWelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .glassEffect(.regular.tint(.blue.opacity(0.1)), in: .circle)
            
            Text("Welcome to Practice Room")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.top, 60)
    }
}

struct ModernGlassMidiKeyboard: View {
    let midiNotes: [Int]
    let showLabels: Bool
    let minNote: Int
    let maxNote: Int
    
    var body: some View {
        // Enhanced version of your MidiKeyboardView with glass effects
        GeometryReader { geometry in
            let whiteKeys = calculateWhiteKeys()
            let keyWidth = geometry.size.width / CGFloat(whiteKeys.count)

            ZStack(alignment: .topLeading) {
                // White keys with glass effects
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.self) { noteNumber in
                        ModernGlassWhiteKey(
                            noteNumber: noteNumber,
                            isHighlighted: midiNotes.contains(noteNumber),
                            showLabel: showLabels,
                            width: keyWidth
                        )
                    }
                }

                // Black keys with glass effects
                ZStack(alignment: .topLeading) {
                    ForEach(Array(whiteKeys.enumerated()), id: \.offset) { index, whiteNote in
                        if let blackNote = blackKeyAfterWhite(whiteNote), blackNote <= maxNote {
                            ModernGlassBlackKey(
                                noteNumber: blackNote,
                                isHighlighted: midiNotes.contains(blackNote),
                                width: keyWidth * 0.6,
                                height: geometry.size.height * 0.64
                            )
                            .offset(x: CGFloat(index + 1) * keyWidth - (keyWidth * 0.6 / 2))
                        }
                    }
                }
            }
            .glassEffect(.regular.interactive(true), in: .rect(cornerRadius: 8))
        }
    }
    
    private func calculateWhiteKeys() -> [Int] {
        var whiteKeys: [Int] = []
        for note in minNote...maxNote {
            let noteClass = note % 12
            if [0, 2, 4, 5, 7, 9, 11].contains(noteClass) {
                whiteKeys.append(note)
            }
        }
        return whiteKeys
    }
    
    private func blackKeyAfterWhite(_ whiteNote: Int) -> Int? {
        let noteClass = whiteNote % 12
        if [0, 2, 5, 7, 9].contains(noteClass) {
            return whiteNote + 1
        }
        return nil
    }
}

struct ModernGlassWhiteKey: View {
    let noteNumber: Int
    let isHighlighted: Bool
    let showLabel: Bool
    let width: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isHighlighted ? .blue.opacity(0.3) : .clear)
            .frame(width: width)
            .overlay(
                Rectangle()
                    .stroke(.primary.opacity(0.2), lineWidth: 1)
            )
            .overlay(
                Group {
                    if showLabel {
                        Text(noteLabel(for: noteNumber))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
            )
            .glassEffect(
                isHighlighted ? .regular.tint(.blue.opacity(0.2)) : .regular,
                in: .rect(cornerRadius: 0)
            )
    }
    
    private func noteLabel(for note: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return noteNames[note % 12]
    }
}

struct ModernGlassBlackKey: View {
    let noteNumber: Int
    let isHighlighted: Bool
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isHighlighted ? .blue.opacity(0.4) : .black.opacity(0.8))
            .frame(width: width, height: height)
            .glassEffect(
                isHighlighted ? .regular.tint(.blue.opacity(0.3)) : .regular.tint(.black.opacity(0.1)),
                in: .rect(cornerRadius: 2)
            )
    }
}

// Removed ModernQuestionMenuSheet - using native iOS 26 Menu instead

// MARK: - Preview

#Preview {
    ModernChatView()
}