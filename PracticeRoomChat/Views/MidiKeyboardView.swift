import SwiftUI

// MARK: - Minimal MIDI keyboard
// Rationale: The previous keyboard used gradients, shadows and animated
// indicators. That looked playful but also busy. This version intentionally
// opts for a flat, minimal design that reads clearly in both light and dark
// modes, without ornamental effects. We keep the same pitch layout so the rest
// of the app (highlight logic, note math) continues to work unchanged.
struct MidiKeyboardView: View {
    let midiNotes: [Int]
    let showLabels: Bool
    let minNote: Int
    let maxNote: Int

    init(midiContent: String, showLabels: Bool = true, minNote: Int = 60, maxNote: Int = 71) {
        // Parse MIDI:60,64,67:2.0s format
        if midiContent.hasPrefix("MIDI:") {
            let components = midiContent.dropFirst(5).components(separatedBy: ":")
            if let noteString = components.first {
                self.midiNotes = noteString.components(separatedBy: ",").compactMap { Int($0) }
            } else {
                self.midiNotes = []
            }
        } else {
            self.midiNotes = []
        }
        self.showLabels = showLabels
        self.minNote = minNote
        self.maxNote = maxNote
    }

    init(midiNotes: [Int], showLabels: Bool = true, minNote: Int = 60, maxNote: Int = 71) {
        self.midiNotes = midiNotes
        self.showLabels = showLabels
        self.minNote = minNote
        self.maxNote = maxNote
    }
    
    var body: some View {
        // Only the keyboard itself; no surrounding card or animated arrows.
        GeometryReader { geometry in
            let _ = print("MidiKeyboardView - midiNotes: \(midiNotes), range: \(minNote)-\(maxNote)")
            let whiteKeys = calculateWhiteKeys()
            let keyWidth = geometry.size.width / CGFloat(whiteKeys.count)

            ZStack(alignment: .topLeading) {
                // White keys row
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.self) { noteNumber in
                        WhiteKey(
                            noteNumber: noteNumber,
                            isHighlighted: midiNotes.contains(noteNumber),
                            showLabel: showLabels,
                            width: keyWidth
                        )
                    }
                }

                // Black keys overlayed above the whites
                ZStack(alignment: .topLeading) {
                    ForEach(Array(whiteKeys.enumerated()), id: \.offset) { index, whiteNote in
                        if let blackNote = blackKeyAfterWhite(whiteNote), blackNote <= maxNote {
                            BlackKey(
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
        }
    }
    
    private func calculateWhiteKeys() -> [Int] {
        var whiteKeys: [Int] = []

        for note in minNote...maxNote {
            let noteClass = note % 12
            // White keys are C(0), D(2), E(4), F(5), G(7), A(9), B(11)
            if [0, 2, 4, 5, 7, 9, 11].contains(noteClass) {
                whiteKeys.append(note)
            }
        }

        return whiteKeys
    }

    private func blackKeyAfterWhite(_ whiteNote: Int) -> Int? {
        let noteClass = whiteNote % 12
        // Black keys exist after C(0), D(2), F(5), G(7), A(9)
        if [0, 2, 5, 7, 9].contains(noteClass) {
            return whiteNote + 1
        }
        return nil
    }
}

struct WhiteKey: View {
    let noteNumber: Int
    let isHighlighted: Bool
    let showLabel: Bool
    let width: CGFloat

    private var noteName: String {
        let names = ["C", "D", "E", "F", "G", "A", "B"]
        let noteClass = noteNumber % 12
        let nameIndex = [0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6][noteClass] ?? 0
        return names[nameIndex]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 0.6)
                )

            // Show note name at the bottom when highlighted
            if isHighlighted {
                Text(noteName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: width)
    }
}

struct BlackKey: View {
    let noteNumber: Int
    let isHighlighted: Bool
    let width: CGFloat
    let height: CGFloat

    private var noteName: String {
        // Map black keys to their sharp names
        let noteClass = noteNumber % 12
        let sharpNames = [1: "C♯", 3: "D♯", 6: "F♯", 8: "G♯", 10: "A♯"]
        return sharpNames[noteClass] ?? ""
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.black.opacity(0.8), lineWidth: 0.6)
                )

            // Show note name in white at the bottom when highlighted
            if isHighlighted {
                Text(noteName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
            }
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        // Default range C4-B4
        MidiKeyboardView(midiContent: "MIDI:60:1.0s")
            .frame(height: 100)
            .padding()

        // Extended range C2-G5
        MidiKeyboardView(midiContent: "MIDI:36,79:2.0s", minNote: 36, maxNote: 79)
            .frame(height: 100)
            .padding()

        // Chord in normal range
        MidiKeyboardView(midiContent: "MIDI:60,64,67:2.0s")
            .frame(height: 100)
            .padding()
    }
}