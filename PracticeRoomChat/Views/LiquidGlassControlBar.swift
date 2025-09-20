import SwiftUI

struct LiquidGlassControlBar: View {
    @Binding var messageText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    let onMenuTap: () -> Void
    @State private var showMicrophoneButton = false
    @State private var micScale: CGFloat = 1.0

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Left floating action button
            FloatingGlassButton(
                icon: "plus",
                size: 56,
                onTap: onMenuTap
            )

            // Main input container with liquid glass effect
            LiquidGlassInputField(
                text: $messageText,
                isTextFieldFocused: $isTextFieldFocused,
                showMicrophoneButton: $showMicrophoneButton,
                onSend: onSend
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct LiquidGlassInputField: View {
    @Binding var text: String
    @FocusState.Binding var isTextFieldFocused: Bool
    @Binding var showMicrophoneButton: Bool
    let onSend: () -> Void

    @State private var rippleEffect = false
    @State private var glowIntensity: Double = 0.0

    var body: some View {
        HStack(spacing: 0) {
            // Text input area
            HStack(spacing: 8) {
                TextField("iMessage", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !text.isEmpty {
                            onSend()
                        }
                    }
                    .lineLimit(1...6)
                    .padding(.vertical, 10)
                    .padding(.leading, 16)
                    .onChange(of: text) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showMicrophoneButton = newValue.isEmpty
                            glowIntensity = newValue.isEmpty ? 0.0 : 0.3
                        }
                    }

                // Microphone or Send button
                Button(action: {
                    if text.isEmpty {
                        // Handle voice input
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rippleEffect.toggle()
                        }
                    } else {
                        onSend()
                    }
                }) {
                    Image(systemName: text.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                        .font(.system(size: text.isEmpty ? 20 : 24))
                        .foregroundColor(text.isEmpty ? .gray : .blue)
                        .scaleEffect(rippleEffect ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rippleEffect)
                }
                .padding(.trailing, 12)
            }
            .background(
                LiquidGlassBackground(
                    glowIntensity: glowIntensity,
                    isActive: isTextFieldFocused
                )
            )
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: .blue.opacity(glowIntensity * 0.3), radius: 20, x: 0, y: 0)
    }
}

struct LiquidGlassBackground: View {
    let glowIntensity: Double
    let isActive: Bool
    @State private var shimmerOffset: CGFloat = -200
    @State private var liquidAnimation: CGFloat = 0

    var body: some View {
        ZStack {
            // Base glass layer - removed as iOS 26 handles this

            // Liquid glass gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Animated shimmer effect
            if isActive {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .mask(Capsule())
                    .onAppear {
                        withAnimation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false)
                        ) {
                            shimmerOffset = 200
                        }
                    }
            }

            // Inner glow
            Capsule()
                .stroke(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(glowIntensity * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 50
                    ),
                    lineWidth: 1
                )
        }
    }
}

struct FloatingGlassButton: View {
    let icon: String
    let size: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var ripple = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                ripple.toggle()
            }
            onTap()
        }) {
            ZStack {
                // Glass background
                Circle()
                    .glassEffect(.regular, in: .circle)
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: size * 0.7
                                )
                            )
                    )

                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .regular))
                    .foregroundColor(.primary)
                    .rotationEffect(.degrees(isPressed ? 45 : 0))

                // Ripple effect overlay
                if ripple {
                    Circle()
                        .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                        .scaleEffect(ripple ? 2 : 1)
                        .opacity(ripple ? 0 : 1)
                        .animation(.easeOut(duration: 0.4), value: ripple)
                }
            }
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}

// Preview
#Preview {
    VStack {
        Spacer()

        LiquidGlassControlBar(
            messageText: .constant(""),
            isTextFieldFocused: FocusState<Bool>().projectedValue,
            onSend: {},
            onMenuTap: {}
        )
        .background(Color.gray.opacity(0.1))
    }
}