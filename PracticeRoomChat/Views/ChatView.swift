import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService(authService: ServiceAccountAuth())
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingExamplesMenu = false
    @State private var detailedQuestions: [String] = []
    @State private var simpleQuestions: [String] = []
    @State private var showingSettings = false
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
                HStack {
                    Button(action: {}) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Practice Room Chat")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Settings button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                
                Spacer()
            }
            
            // Bottom section with keyboard and input
            VStack(spacing: 0) {
                Spacer()
                
                // Piano keyboard - always visible with dynamic range
                MidiKeyboardView(
                    midiNotes: Array(soundEngine.currentlyPlayingNotes),
                    showLabels: true,
                    minNote: soundEngine.keyboardRange.minNote,
                    maxNote: soundEngine.keyboardRange.maxNote
                )
                .frame(height: 180)
                .frame(maxWidth: 300) // Limit width to make it more compact
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
                if chatService.messages.isEmpty {
                    SuggestionChips()
                        .environmentObject(chatService)
                        .padding(.bottom, 8)
                }
                
                // Simple bottom bar with ultraThinMaterial
                HStack(spacing: 12) {
                    Menu {
                        Section("📚 Detailed Explanations") {
                            ForEach(detailedQuestions, id: \.self) { question in
                                Button(action: {
                                    messageText = question
                                    sendMessage()
                                }) {
                                    Text(question)
                                }
                            }
                        }

                        Section("🎵 Simple Playback") {
                            ForEach(simpleQuestions, id: \.self) { question in
                                Button(action: {
                                    messageText = question
                                    sendMessage()
                                }) {
                                    Text(question)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "book.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        TextField("Message", text: $messageText)
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
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

struct SuggestionChips: View {
    let suggestions = [
        "What is a major chord?",
        "Show me the C major scale"
    ]
    @EnvironmentObject var chatService: ChatService
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {
                    chatService.sendMessage(suggestion)
                }) {
                    Text(suggestion)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
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

#Preview {
    ChatView()
}