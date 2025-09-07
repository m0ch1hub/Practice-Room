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
    let octaves: Int
    
    init(midiContent: String, showLabels: Bool = true, octaves: Int = 1) {
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
        self.octaves = max(1, octaves)
    }
    
    init(midiNotes: [Int], showLabels: Bool = true, octaves: Int = 1) {
        self.midiNotes = midiNotes
        self.showLabels = showLabels
        self.octaves = max(1, octaves)
    }
    
    var body: some View {
        // Only the keyboard itself; no surrounding card or animated arrows.
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // White keys row
                HStack(spacing: 0) {
                    ForEach(0..<(octaves * 7), id: \.self) { index in
                        WhiteKey(
                            noteNumber: whiteKeyMidiNumber(for: index),
                            isHighlighted: midiNotes.contains(whiteKeyMidiNumber(for: index)),
                            showLabel: showLabels,
                            width: geometry.size.width / CGFloat(octaves * 7)
                        )
                    }
                }
                
                // Black keys overlayed above the whites
                ZStack(alignment: .topLeading) {
                    ForEach(0..<(octaves * 7), id: \.self) { index in
                        if shouldShowBlackKey(afterWhiteIndex: index) {
                            BlackKey(
                                noteNumber: blackKeyMidiNumber(afterWhiteIndex: index),
                                isHighlighted: midiNotes.contains(blackKeyMidiNumber(afterWhiteIndex: index)),
                                width: geometry.size.width / CGFloat(octaves * 7) * 0.6,
                                height: geometry.size.height * 0.64
                            )
                            .offset(x: blackKeyOffset(afterWhiteIndex: index, keyWidth: geometry.size.width / CGFloat(octaves * 7)))
                        }
                    }
                }
            }
        }
        .frame(height: 100)
    }
    
    private func whiteKeyMidiNumber(for index: Int) -> Int {
        let whiteKeyPattern = [0, 2, 4, 5, 7, 9, 11] // C, D, E, F, G, A, B
        // MIDI 60 = C4, so we want octave 5 in MIDI numbering (60/12 = 5)
        let octave = 5 // This gives us C4 (60) to B4 (71)
        let noteInOctave = whiteKeyPattern[index % 7]
        return (octave * 12) + noteInOctave
    }
    
    private func blackKeyMidiNumber(afterWhiteIndex index: Int) -> Int {
        // Black key after a given white key is one semitone up
        return whiteKeyMidiNumber(for: index) + 1
    }
    
    private func shouldShowBlackKey(afterWhiteIndex index: Int) -> Bool {
        // Show black keys after C, D, F, G, A within each octave
        let pos = index % 7
        return pos == 0 || pos == 1 || pos == 3 || pos == 4 || pos == 5
    }
    
    private func blackKeyOffset(afterWhiteIndex index: Int, keyWidth: CGFloat) -> CGFloat {
        // Centered on the boundary to the right of the white key at `index`
        let blackKeyWidth = keyWidth * 0.6
        return CGFloat(index + 1) * keyWidth - (blackKeyWidth / 2)
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
        // Flat white key with a subtle outline. If highlighted, we tint the
        // key with a light accent overlay. We only label the C keys to avoid
        // visual noise.
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 0.6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(isHighlighted ? 0.18 : 0.0))
                )
            if showLabel && noteNumber % 12 == 0 { // Only show C labels
                Text("C\(noteNumber / 12 - 1)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isHighlighted ? Color.blue : .secondary)
                    .padding(.bottom, 6)
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
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.black)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(0.8), lineWidth: 0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(isHighlighted ? 0.22 : 0.0))
            )
    }
}


#Preview {
    VStack(spacing: 20) {
        // Single note
        MidiKeyboardView(midiContent: "MIDI:60:1.0s")
            .padding()
        
        // Chord
        MidiKeyboardView(midiContent: "MIDI:60,64,67:2.0s")
            .padding()
        
        // Interval
        MidiKeyboardView(midiContent: "MIDI:60,67:1.5s")
            .padding()
    }
}