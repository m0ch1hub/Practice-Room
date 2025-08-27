import SwiftUI

struct MidiKeyboardView: View {
    let midiNotes: [Int]
    let showLabels: Bool
    @State private var animateArrows = false
    
    init(midiContent: String, showLabels: Bool = true) {
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
    }
    
    init(midiNotes: [Int], showLabels: Bool = true) {
        self.midiNotes = midiNotes
        self.showLabels = showLabels
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Arrows pointing to active notes
            GeometryReader { geometry in
                ZStack {
                    ForEach(midiNotes, id: \.self) { note in
                        ArrowIndicator(
                            midiNote: note,
                            keyboardWidth: geometry.size.width,
                            animate: animateArrows
                        )
                    }
                }
            }
            .frame(height: 30)
            
            // Keyboard
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // White keys
                    HStack(spacing: 1) {
                        ForEach(0..<14, id: \.self) { index in
                            WhiteKey(
                                noteNumber: whiteKeyMidiNumber(for: index),
                                isHighlighted: midiNotes.contains(whiteKeyMidiNumber(for: index)),
                                showLabel: showLabels,
                                width: (geometry.size.width - 13) / 14
                            )
                        }
                    }
                    
                    // Black keys
                    HStack(spacing: 0) {
                        ForEach(0..<14, id: \.self) { index in
                            if shouldShowBlackKey(at: index) {
                                BlackKey(
                                    noteNumber: blackKeyMidiNumber(for: index),
                                    isHighlighted: midiNotes.contains(blackKeyMidiNumber(for: index)),
                                    width: (geometry.size.width - 13) / 14 * 0.6,
                                    height: geometry.size.height * 0.6
                                )
                                .offset(x: blackKeyOffset(for: index, keyWidth: (geometry.size.width - 13) / 14))
                            }
                        }
                    }
                }
            }
            .frame(height: 80)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animateArrows = true
            }
        }
    }
    
    private func whiteKeyMidiNumber(for index: Int) -> Int {
        let whiteKeyPattern = [0, 2, 4, 5, 7, 9, 11] // C, D, E, F, G, A, B
        let octave = (index / 7) + 4 // Start from C4
        let noteInOctave = whiteKeyPattern[index % 7]
        return (octave * 12) + noteInOctave
    }
    
    private func blackKeyMidiNumber(for index: Int) -> Int {
        let blackKeyMap: [Int: Int] = [
            0: 61,  // C#4
            1: 63,  // D#4
            3: 66,  // F#4
            4: 68,  // G#4
            5: 70,  // A#4
            7: 73,  // C#5
            8: 75,  // D#5
            10: 78, // F#5
            11: 80, // G#5
            12: 82  // A#5
        ]
        return blackKeyMap[index] ?? 0
    }
    
    private func shouldShowBlackKey(at index: Int) -> Bool {
        let pattern = [true, true, false, true, true, true, false] // C#, D#, skip, F#, G#, A#, skip
        if index >= 14 { return false }
        return pattern[index % 7] && index != 2 && index != 6 && index != 9 && index != 13
    }
    
    private func blackKeyOffset(for index: Int, keyWidth: CGFloat) -> CGFloat {
        let positions: [Int: CGFloat] = [
            0: 0.65,   // C#
            1: 1.35,   // D#
            3: 3.65,   // F#
            4: 4.35,   // G#
            5: 5.35,   // A#
            7: 7.65,   // C#
            8: 8.35,   // D#
            10: 10.65, // F#
            11: 11.35, // G#
            12: 12.35  // A#
        ]
        return (positions[index] ?? 0) * keyWidth
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
        VStack {
            Spacer()
            if showLabel && noteNumber % 12 == 0 { // Show C labels
                Text("C\(noteNumber / 12 - 1)")
                    .font(.system(size: 10))
                    .foregroundColor(isHighlighted ? .white : .gray)
                    .padding(.bottom, 4)
            }
        }
        .frame(width: width)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(isHighlighted ? Color.blue : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
        )
    }
}

struct BlackKey: View {
    let noteNumber: Int
    let isHighlighted: Bool
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(isHighlighted ? Color.blue.opacity(0.8) : Color.black)
            .frame(width: width, height: height)
            .overlay(
                Rectangle()
                    .stroke(Color.gray, lineWidth: 0.5)
            )
    }
}

struct ArrowIndicator: View {
    let midiNote: Int
    let keyboardWidth: CGFloat
    let animate: Bool
    
    private var xPosition: CGFloat {
        // Calculate position based on MIDI note
        let noteClass = midiNote % 12
        let octaveOffset = CGFloat((midiNote / 12) - 4) * 7 // Octaves from C4
        
        let positionMap: [Int: CGFloat] = [
            0: 0.5,   // C
            1: 0.85,  // C#
            2: 1.5,   // D
            3: 2.15,  // D#
            4: 2.5,   // E
            5: 3.5,   // F
            6: 3.85,  // F#
            7: 4.5,   // G
            8: 5.15,  // G#
            9: 5.5,   // A
            10: 5.85, // A#
            11: 6.5   // B
        ]
        
        let basePosition = positionMap[noteClass] ?? 0
        let keyWidth = (keyboardWidth - 13) / 14
        return (basePosition + octaveOffset) * keyWidth
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .scaleEffect(animate ? 1.2 : 1.0)
            
            Text(noteName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.blue)
        }
        .position(x: xPosition, y: 15)
    }
    
    private var noteName: String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = midiNote / 12 - 1
        return "\(names[midiNote % 12])\(octave)"
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