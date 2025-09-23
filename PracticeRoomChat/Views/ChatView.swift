import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService(authService: ServiceAccountAuth())
    @StateObject private var soundEngine = SoundEngine.shared
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var selectedQuestion = "What is a major chord?"
    @State private var showingExamplesMenu = false
    @State private var showingSettings = false
    @State private var detailedQuestions: [String] = []
    @State private var simpleQuestions: [String] = []
    @State private var hasAnsweredCurrentQuestion = false
    @AppStorage("notationDisplay") private var notationDisplay = NotationDisplay.keyboard.rawValue
    
    var body: some View {
        ZStack {
            // Chat content - extends full screen
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Top padding to account for header
                        Color.clear.frame(height: 80)
                        
                        if chatService.messages.isEmpty {
                            // Show the selected question
                            Text(selectedQuestion)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.top, 60)
                                .padding(.horizontal, 20)
                                .multilineTextAlignment(.center)
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
            
            // Simple header with ultraThinMaterial and settings
            VStack {
                HStack {
                    Text("Practice Room")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
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


                // Simplified control bar with preset questions
                PresetQuestionControlBar(
                    selectedQuestion: $selectedQuestion,
                    hasAnsweredCurrentQuestion: $hasAnsweredCurrentQuestion,
                    onSend: sendSelectedQuestion,
                    detailedQuestions: detailedQuestions,
                    simpleQuestions: simpleQuestions,
                    onQuestionSelected: { question in
                        selectedQuestion = question
                        hasAnsweredCurrentQuestion = false
                        // Clear messages when switching questions
                        chatService.messages.removeAll()
                    }
                )
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            loadAvailableQuestions()
        }
        .sheet(isPresented: $showingSettings) {
            FeedbackSettingsView()
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
    
    private func sendSelectedQuestion() {
        guard !hasAnsweredCurrentQuestion else { return }
        Logger.shared.ui("Sending selected question: '\(selectedQuestion)'")
        hasAnsweredCurrentQuestion = true
        chatService.sendMessage(selectedQuestion)
    }


    // Removed playExample function - audio is now handled by ProgressiveResponseView
}

struct ChatMessageView: View {
    let message: ChatMessage
    let scrollProxy: ScrollViewProxy
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var userQuestion = ""
    @State private var showingFeedbackSheet = false
    @State private var pendingFeedback: (messageId: UUID, question: String, answer: String, rating: FeedbackItem.Rating)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.role == "user" {
                // User message
                Text(message.content)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear {
                        userQuestion = message.content
                    }
            } else {
                // Assistant response with progressive reveal
                VStack(alignment: .leading, spacing: 12) {
                    ProgressiveResponseView(
                        response: ProgressiveResponse.parse(message.content),
                        scrollProxy: scrollProxy,
                        messageId: message.id
                    )

                    // Feedback buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            showFeedbackSubmission(
                                messageId: message.id,
                                question: userQuestion,
                                answer: message.content,
                                rating: .thumbsUp
                            )
                        }) {
                            Image(systemName: feedbackManager.getRating(for: message.id) == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .font(.system(size: 16))
                                .foregroundColor(feedbackManager.getRating(for: message.id) == .thumbsUp ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            showFeedbackSubmission(
                                messageId: message.id,
                                question: userQuestion,
                                answer: message.content,
                                rating: .thumbsDown
                            )
                        }) {
                            Image(systemName: feedbackManager.getRating(for: message.id) == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                .font(.system(size: 16))
                                .foregroundColor(feedbackManager.getRating(for: message.id) == .thumbsDown ? .red : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            if let feedback = pendingFeedback {
                FeedbackSubmissionView(
                    messageId: feedback.messageId,
                    question: feedback.question,
                    answer: feedback.answer,
                    initialRating: feedback.rating,
                    isPresented: $showingFeedbackSheet
                )
            }
        }
    }

    private func showFeedbackSubmission(messageId: UUID, question: String, answer: String, rating: FeedbackItem.Rating) {
        pendingFeedback = (messageId, question, answer, rating)
        showingFeedbackSheet = true
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


// Simplified control bar for preset questions only
struct PresetQuestionControlBar: View {
    @Binding var selectedQuestion: String
    @Binding var hasAnsweredCurrentQuestion: Bool
    let onSend: () -> Void
    let detailedQuestions: [String]
    let simpleQuestions: [String]
    let onQuestionSelected: (String) -> Void

    @State private var isMenuPressed = false
    @State private var showQuestionSheet = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Menu button
            Button(action: {
                showQuestionSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(.regularMaterial)
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.primary)
                        .scaleEffect(isMenuPressed ? 0.95 : 1.0)
                }
            }
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
            .sheet(isPresented: $showQuestionSheet) {
                PresetQuestionSelectorSheet(
                    detailedQuestions: detailedQuestions,
                    simpleQuestions: simpleQuestions,
                    onQuestionSelected: onQuestionSelected,
                    isPresented: $showQuestionSheet
                )
                .presentationDetents([.medium, .large])
            }

            // Display selected question (read-only)
            HStack(spacing: 8) {
                Text(selectedQuestion)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Submit button
                Button(action: {
                    if !hasAnsweredCurrentQuestion {
                        onSend()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(hasAnsweredCurrentQuestion ? .secondary : .blue)
                }
                .disabled(hasAnsweredCurrentQuestion)
                .padding(.trailing, 12)
            }
            .glassEffect(
                .regular,
                in: .capsule
            )
        }
        .padding(.horizontal, 16)
    }
}

// New sheet for preset question selection
struct PresetQuestionSelectorSheet: View {
    let detailedQuestions: [String]
    let simpleQuestions: [String]
    let onQuestionSelected: (String) -> Void
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                if !detailedQuestions.isEmpty {
                    Section("Questions") {
                        ForEach(detailedQuestions, id: \.self) { question in
                            Button(action: {
                                onQuestionSelected(question)
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.blue)
                                    Text(question)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                if !simpleQuestions.isEmpty {
                    Section("Commands") {
                        ForEach(simpleQuestions, id: \.self) { question in
                            Button(action: {
                                onQuestionSelected(question)
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "play.circle")
                                        .foregroundColor(.green)
                                    Text(question)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select a Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView()
}