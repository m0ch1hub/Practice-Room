import SwiftUI

struct PianoKeyboardView: View {
    let highlightedNotes: [Int]
    let isVisible: Bool
    
    private let whiteKeys = [0, 2, 4, 5, 7, 9, 11]
    private let blackKeys = [1, 3, 6, 8, 10]
    
    var body: some View {
        ZStack {
            if isVisible {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(0..<12, id: \.self) { note in
                            if whiteKeys.contains(note % 12) {
                                whiteKeyView(for: note)
                            }
                        }
                    }
                    .overlay(
                        HStack(spacing: 0) {
                            blackKeyOverlay()
                        }
                    )
                }
                .frame(height: 120)
                .background(Color.black.opacity(0.1))
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
            }
        }
    }
    
    private func whiteKeyView(for note: Int) -> some View {
        Rectangle()
            .fill(highlightedNotes.contains(note % 12) ? Color.blue.opacity(0.6) : Color.white)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            .overlay(
                VStack {
                    Spacer()
                    if highlightedNotes.contains(note % 12) {
                        Text(noteLabel(for: note % 12))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                    }
                }
            )
            .animation(.easeInOut(duration: 0.2), value: highlightedNotes)
    }
    
    private func blackKeyOverlay() -> some View {
        HStack(spacing: 0) {
            blackKeyView(for: 1, offset: 25)
            blackKeyView(for: 3, offset: 25)
            Spacer().frame(width: 50)
            blackKeyView(for: 6, offset: 16)
            blackKeyView(for: 8, offset: 16)
            blackKeyView(for: 10, offset: 16)
            Spacer()
        }
        .padding(.horizontal, 12)
    }
    
    private func blackKeyView(for note: Int, offset: CGFloat) -> some View {
        Rectangle()
            .fill(highlightedNotes.contains(note) ? Color.blue.opacity(0.8) : Color.black)
            .frame(width: 30, height: 75)
            .cornerRadius(4, corners: [.bottomLeft, .bottomRight])
            .overlay(
                VStack {
                    Spacer()
                    if highlightedNotes.contains(note) {
                        Text(noteLabel(for: note))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                    }
                }
            )
            .offset(x: offset)
            .animation(.easeInOut(duration: 0.2), value: highlightedNotes)
    }
    
    private func noteLabel(for note: Int) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return noteNames[note]
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack {
        Spacer()
        PianoKeyboardView(highlightedNotes: [0, 4, 7], isVisible: true)
    }
    .background(Color.gray.opacity(0.1))
}