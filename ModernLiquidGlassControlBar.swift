import SwiftUI

/// iOS 26 Liquid Glass Control Bar using the new .glassEffect() API
/// Implements Apple's Liquid Glass design system introduced in iOS 26
struct ModernLiquidGlassControlBar: View {
    @Binding var messageText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    let onMenuTap: () -> Void

    @State private var isInteracting = false
    @Namespace private var glassNamespace

    var body: some View {
        // GlassEffectContainer groups glass elements for proper visual sampling
        // Note: This is conceptual iOS 26 API - actual implementation may vary
        HStack(alignment: .bottom, spacing: 16) {
            // Modern Glass Menu Button
            ModernGlassMenuButton(onTap: onMenuTap)

            // Modern Glass Input Field
            ModernGlassInputField(
                text: $messageText,
                isTextFieldFocused: $isTextFieldFocused,
                onSend: onSend
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct ModernGlassMenuButton: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        // iOS 26 Liquid Glass button style
        // Note: Fallback to material design for pre-iOS 26
        .glassEffect(.regular.interactive(true), in: .circle)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}

struct ModernGlassInputField: View {
    @Binding var text: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void

    @State private var showMicrophone = true

    var body: some View {
        HStack(spacing: 8) {
            // Text Input
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
                .focused($isTextFieldFocused)
                .lineLimit(1...6)
                .padding(.vertical, 12)
                .padding(.leading, 16)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
                .onChange(of: text) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showMicrophone = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                }

            // Action Button (Microphone or Send)
            Button(action: {
                if showMicrophone {
                    // Handle voice input
                    handleVoiceInput()
                } else {
                    onSend()
                }
            }) {
                Image(systemName: showMicrophone ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.system(size: showMicrophone ? 20 : 24))
                    .foregroundColor(showMicrophone ? .secondary : .blue)
            }
            .padding(.trailing, 12)
        }
        .glassEffect(
            .regular
                .tint(isTextFieldFocused ? .blue.opacity(0.1) : .clear)
                .interactive(true),
            in: .capsule
        )
    }
    
    private func handleVoiceInput() {
        // Voice input implementation
        print("Voice input requested")
    }
}

// MARK: - Enhanced Glass Components for other UI elements

struct ModernGlassSuggestionChips: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSuggestionTap(suggestion)
                    }) {
                        Text(suggestion)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ModernGlassMessageBubble: View {
    let message: String
    let isUser: Bool

    var body: some View {
        HStack {
            if isUser { Spacer() }

            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(
                    .regular
                        .tint(isUser ? .blue.opacity(0.1) : .clear)
                        .interactive(false),
                    in: .rect(cornerRadius: 18)
                )

            if !isUser { Spacer() }
        }
    }
}

struct ModernGlassHeader: View {
    let title: String
    let onMenuTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onMenuTap) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button(action: onSettingsTap) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(
            .regular.interactive(false),
            in: .rect(cornerRadius: 0)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        // Example usage of the modern components
        VStack(spacing: 20) {
            ModernGlassHeader(
                title: "Practice Room Chat",
                onMenuTap: {},
                onSettingsTap: {}
            )
            
            Spacer()
            
            ModernGlassMessageBubble(
                message: "What is a major chord?",
                isUser: true
            )
            
            ModernGlassMessageBubble(
                message: "A major chord consists of a root, major third, and perfect fifth.",
                isUser: false
            )
            
            ModernGlassSuggestionChips(
                suggestions: ["What is a major chord?", "Show me C major scale"],
                onSuggestionTap: { _ in }
            )
            
            ModernLiquidGlassControlBar(
                messageText: .constant(""),
                isTextFieldFocused: FocusState<Bool>().projectedValue,
                onSend: {},
                onMenuTap: {}
            )
        }
    }
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}