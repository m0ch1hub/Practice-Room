import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService(authService: ServiceAccountAuth())
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingExamplesMenu = false
    @State private var detailedQuestions: [String] = []
    @State private var simpleQuestions: [String] = []
    @AppStorage("notationDisplay") private var notationDisplay = NotationDisplay.keyboard.rawValue
    // Removed showingQuestionMenu - using native menu instead
    // Removed showSlidesView state
    
    var body: some View {
        ZStack {
            // Chat content - extends full screen
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Top padding to account for header
                        Color.clear.frame(height: 80)
                        
                        if chatService.messages.isEmpty {
                            WelcomeView()
                                .padding(.top, 40)
                        }
                        
                        ForEach(chatService.messages) { message in
                            ChatMessageView(
                                message: message,
                                scrollProxy: proxy
                            )
                            .id(message.id)
                        }
                        
                        if chatService.isLoading {
                            LoadingIndicator()
                                .id("loading")
                        }
                        
                        // Bottom anchor for scrolling - adjusted for piano visibility
                        Color.clear
                            .frame(height: 280) // Adjusted for taller piano
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
            .ignoresSafeArea()
            
            // Simple header with ultraThinMaterial
            VStack {
                Text("Practice Room")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: 0))
                
                Spacer()
            }
            
            // Bottom section with keyboard and input
            VStack(spacing: 0) {
                Spacer()

                // Notation display - switch between keyboard, staff, or both
                Group {
                    switch NotationDisplay(rawValue: notationDisplay) ?? .keyboard {
                    case .keyboard:
                        MidiKeyboardView(
                            midiNotes: Array(soundEngine.currentlyPlayingNotes),
                            showLabels: true,
                            minNote: soundEngine.keyboardRange.minNote,
                            maxNote: soundEngine.keyboardRange.maxNote
                        )
                        .frame(height: 180)
                        .frame(maxWidth: 300) // Limit width to make it more compact

                    case .staff:
                        StaffNotationView(
                            midiNotes: Array(soundEngine.currentlyPlayingNotes),
                            showLabels: true,
                            minNote: soundEngine.keyboardRange.minNote,
                            maxNote: soundEngine.keyboardRange.maxNote
                        )
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)

                    case .both:
                        VStack(spacing: 8) {
                            StaffNotationView(
                                midiNotes: Array(soundEngine.currentlyPlayingNotes),
                                showLabels: false,
                                minNote: soundEngine.keyboardRange.minNote,
                                maxNote: soundEngine.keyboardRange.maxNote
                            )
                            .frame(height: 85)
                            .frame(maxWidth: .infinity)

                            MidiKeyboardView(
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
                .padding(.bottom, 8)


                // iOS 26 Liquid Glass Control Bar
                // iOS 26 Liquid Glass Control Bar with integrated menu
                LiquidGlassControlBarWithMenu(
                    messageText: $messageText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: sendMessage,
                    detailedQuestions: detailedQuestions,
                    simpleQuestions: simpleQuestions
                )
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isTextFieldFocused = false
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Dismiss keyboard on swipe down
                    if value.translation.height > 50 {
                        isTextFieldFocused = false
                    }
                }
        )
        .onAppear {
            loadAvailableQuestions()
        }
        // Removed sheet - using native menu instead
        // Removed fullScreenCover for slides
    }
    
    private func loadAvailableQuestions() {
        // Load only main questions for menu display (filters out variations)
        let examples = TrainingDataManager.shared.loadMainQuestions()

        // Get all user prompts from main questions only
        let allQuestions = examples.compactMap { example in
            example.contents.first(where: { $0.role == "user" })?.parts.first?.text
        }

        // Separate into detailed (questions) and simple (commands)
        detailedQuestions = allQuestions.filter { question in
            question.lowercased().starts(with: "what")
        }

        simpleQuestions = allQuestions.filter { question in
            question.lowercased().starts(with: "play")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let message = messageText
        Logger.shared.ui("Sending message from ChatView: '\(message)'")
        messageText = ""
        isTextFieldFocused = false // Dismiss keyboard
        chatService.sendMessage(message)
    }
    
    // Removed playExample function - audio is now handled by ProgressiveResponseView
}

struct ChatMessageView: View {
    let message: ChatMessage
    let scrollProxy: ScrollViewProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.role == "user" {
                // User message
                Text(message.content)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Assistant response with progressive reveal
                ProgressiveResponseView(
                    response: ProgressiveResponse.parse(message.content),
                    scrollProxy: scrollProxy,
                    messageId: message.id
                )
                .padding(.vertical, 8)
            }
        }
    }
}

// Removed PlayButton - audio is now handled inline


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

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.blue)
        }
        .padding(.top, 60)
    }
}

// iOS 26 Liquid Glass Control Bar with integrated native menu
struct LiquidGlassControlBarWithMenu: View {
    @Binding var messageText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    let detailedQuestions: [String]
    let simpleQuestions: [String]

    @Namespace private var glassNamespace
    @State private var isMenuPressed = false

    var body: some View {
        GlassEffectContainer(spacing: 16.0) {
            HStack(alignment: .bottom, spacing: 16) {
                // Native iOS 26 Menu with glass effect
                Menu {
                    if !detailedQuestions.isEmpty {
                        Section("Questions") {
                            ForEach(detailedQuestions, id: \.self) { question in
                                Button(action: {
                                    messageText = question
                                    onSend()
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
                                    onSend()
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
                        .scaleEffect(isMenuPressed ? 0.95 : 1.0)
                }
                .buttonStyle(.glass)
                .glassEffectID("menuButton", in: glassNamespace)
                .onLongPressGesture(
                    minimumDuration: 0,
                    maximumDistance: .infinity,
                    pressing: { pressing in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isMenuPressed = pressing
                        }
                    },
                    perform: { }
                )

                // Glass input field
                HStack(spacing: 8) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.primary)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...6)
                        .padding(.vertical, 12)
                        .padding(.leading, 16)
                        .onSubmit {
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSend()
                            }
                        }

                    Button(action: {
                        if !messageText.isEmpty {
                            onSend()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(messageText.isEmpty ? .secondary : .blue)
                    }
                    .padding(.trailing, 12)
                }
                .glassEffect(
                    .regular
                        .tint(isTextFieldFocused ? .blue.opacity(0.1) : .clear)
                        .interactive(true),
                    in: .capsule
                )
                .glassEffectID("inputField", in: glassNamespace)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    ChatView()
}