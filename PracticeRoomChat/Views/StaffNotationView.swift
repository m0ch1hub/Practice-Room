import SwiftUI

// MARK: - Staff Notation Display
// A musical staff view that displays MIDI notes on traditional five-line staff notation
// Phase 1: Basic display with quarter notes, automatic clef selection, and ledger lines

struct StaffNotationView: View {
    let midiNotes: [Int]
    let showLabels: Bool
    let minNote: Int
    let maxNote: Int

    // Staff configuration
    private let lineSpacing: CGFloat = 18  // Space between staff lines (increased for better visibility)
    private let staffLineCount = 5
    private let noteHeadWidth: CGFloat = 16
    private let noteHeadHeight: CGFloat = 12

    // Clef ranges for auto-detection
    private let trebleClefRange = 60...83  // C4 to B5
    private let bassClefRange = 36...59    // C2 to B3

    init(midiContent: String, showLabels: Bool = true, minNote: Int = 60, maxNote: Int = 71) {
        // Parse MIDI:60,64,67:2.0s format (same as MidiKeyboardView)
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
        Canvas { context, size in
            let clef = determineClef()
            // Center the staff vertically
            let staffHeight = lineSpacing * CGFloat(staffLineCount - 1)
            let staffTop = (size.height - staffHeight) / 2

            // Draw staff lines
            drawStaffLines(context: context, width: size.width, top: staffTop)

            // Draw clef symbol
            drawClef(context: context, clef: clef, x: 25, top: staffTop)

            // Draw notes
            let noteStartX = size.width * 0.2  // Start after clef with more space
            drawNotes(context: context, clef: clef, startX: noteStartX, staffTop: staffTop, canvasWidth: size.width)
        }
        .background(Color.clear)
    }

    // MARK: - Clef Detection
    private func determineClef() -> ClefType {
        // Determine clef based on the range of notes being displayed
        let avgNote = midiNotes.isEmpty ? minNote : midiNotes.reduce(0, +) / midiNotes.count

        if avgNote >= 60 {  // C4 and above
            return .treble
        } else {
            return .bass
        }
    }

    // MARK: - Drawing Functions
    private func drawStaffLines(context: GraphicsContext, width: CGFloat, top: CGFloat) {
        var path = Path()

        for i in 0..<staffLineCount {
            let y = top + CGFloat(i) * lineSpacing
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }

        context.stroke(path, with: .color(.primary.opacity(0.6)), lineWidth: 1.5)
    }

    private func drawClef(context: GraphicsContext, clef: ClefType, x: CGFloat, top: CGFloat) {
        let clefSymbol: String
        let clefSize: CGFloat
        let yOffset: CGFloat

        switch clef {
        case .treble:
            clefSymbol = "𝄞"  // Unicode treble clef
            clefSize = 80  // Larger size for better visibility
            // Position treble clef so it properly wraps around G line (2nd line from bottom)
            yOffset = top + lineSpacing * 2 - 5  // Centered on staff
        case .bass:
            clefSymbol = "𝄢"  // Unicode bass clef
            clefSize = 60  // Proportionally sized
            // Position bass clef on F line (2nd line from top)
            yOffset = top + lineSpacing * 0.8  // Positioned on F line
        }

        context.draw(
            Text(clefSymbol)
                .font(.system(size: clefSize))
                .foregroundColor(.primary),
            at: CGPoint(x: x + 20, y: yOffset + lineSpacing)
        )
    }

    private func drawNotes(context: GraphicsContext, clef: ClefType, startX: CGFloat, staffTop: CGFloat, canvasWidth: CGFloat) {
        guard !midiNotes.isEmpty else { return }

        // Sort notes for better visual arrangement
        let sortedNotes = midiNotes.sorted()

        // Calculate horizontal spacing for notes
        let availableWidth = canvasWidth - startX - 40
        let noteSpacing = min(availableWidth / CGFloat(sortedNotes.count + 1), 80)

        for (index, midiNote) in sortedNotes.enumerated() {
            let x = startX + CGFloat(index + 1) * noteSpacing
            let (y, needsLedger) = calculateNotePosition(midiNote: midiNote, clef: clef, staffTop: staffTop)

            // Draw ledger lines if needed
            if needsLedger {
                drawLedgerLines(context: context, x: x, y: y, staffTop: staffTop, midiNote: midiNote)
            }

            // Draw note head (filled for quarter note)
            drawNoteHead(context: context, x: x, y: y, filled: true)

            // Draw stem (all quarter notes have stems)
            drawStem(context: context, x: x, y: y, midiNote: midiNote, staffTop: staffTop)

            // Draw note label if enabled
            if showLabels {
                drawNoteLabel(context: context, x: x, y: y, midiNote: midiNote)
            }
        }
    }

    private func drawNoteHead(context: GraphicsContext, x: CGFloat, y: CGFloat, filled: Bool) {
        var path = Path()

        // Create oval note head
        path.addEllipse(in: CGRect(
            x: x - noteHeadWidth/2,
            y: y - noteHeadHeight/2,
            width: noteHeadWidth,
            height: noteHeadHeight
        ))

        if filled {
            context.fill(path, with: .color(.primary))
        } else {
            context.stroke(path, with: .color(.primary), lineWidth: 2)
        }
    }

    private func drawStem(context: GraphicsContext, x: CGFloat, y: CGFloat, midiNote: Int, staffTop: CGFloat) {
        let stemHeight: CGFloat = 50  // Increased for larger staff
        let staffMiddle = staffTop + lineSpacing * 2

        // Stems go up for notes below middle line, down for notes above
        let stemUp = y > staffMiddle

        var path = Path()
        if stemUp {
            // Stem on right side, going up
            path.move(to: CGPoint(x: x + noteHeadWidth/2 - 1, y: y))
            path.addLine(to: CGPoint(x: x + noteHeadWidth/2 - 1, y: y - stemHeight))
        } else {
            // Stem on left side, going down
            path.move(to: CGPoint(x: x - noteHeadWidth/2 + 1, y: y))
            path.addLine(to: CGPoint(x: x - noteHeadWidth/2 + 1, y: y + stemHeight))
        }

        context.stroke(path, with: .color(.primary), lineWidth: 2)
    }

    private func drawLedgerLines(context: GraphicsContext, x: CGFloat, y: CGFloat, staffTop: CGFloat, midiNote: Int) {
        let ledgerWidth: CGFloat = 28
        let staffBottom = staffTop + lineSpacing * 4

        var path = Path()

        // Above staff
        if y < staffTop {
            var ledgerY = staffTop - lineSpacing
            while ledgerY >= y - lineSpacing/2 {
                path.move(to: CGPoint(x: x - ledgerWidth/2, y: ledgerY))
                path.addLine(to: CGPoint(x: x + ledgerWidth/2, y: ledgerY))
                ledgerY -= lineSpacing
            }
        }

        // Below staff
        if y > staffBottom {
            var ledgerY = staffBottom + lineSpacing
            while ledgerY <= y + lineSpacing/2 {
                path.move(to: CGPoint(x: x - ledgerWidth/2, y: ledgerY))
                path.addLine(to: CGPoint(x: x + ledgerWidth/2, y: ledgerY))
                ledgerY += lineSpacing
            }
        }

        context.stroke(path, with: .color(.primary.opacity(0.5)), lineWidth: 1.5)
    }

    private func drawNoteLabel(context: GraphicsContext, x: CGFloat, y: CGFloat, midiNote: Int) {
        let noteName = getNoteNameFromMidi(midiNote)

        context.draw(
            Text(noteName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.blue),
            at: CGPoint(x: x, y: y + 25)
        )
    }

    // MARK: - Note Position Calculation
    private func calculateNotePosition(midiNote: Int, clef: ClefType, staffTop: CGFloat) -> (y: CGFloat, needsLedger: Bool) {
        // Map MIDI notes to staff positions
        // Each staff position represents a line or space

        let noteToStaffPosition: [Int: CGFloat]  // Maps note class to position offset
        let referenceNote: Int  // MIDI note for reference position
        let referencePosition: CGFloat  // Staff position for reference note

        switch clef {
        case .treble:
            // E4 (MIDI 64) is on the bottom line of treble clef
            referenceNote = 64  // E4
            referencePosition = 4  // Bottom line (0=top line, 4=bottom line)
            // Map note classes to their relative positions
            // E->F = 0.5, F->G = 1, G->A = 1, A->B = 1, B->C = 0.5, C->D = 1, D->E = 1
            noteToStaffPosition = [
                0: -1.0,   // C (below E)
                1: -1.0,   // C#
                2: -0.5,   // D
                3: -0.5,   // D#
                4: 0.0,    // E (reference)
                5: 0.5,    // F
                6: 0.5,    // F#
                7: 1.0,    // G
                8: 1.0,    // G#
                9: 1.5,    // A
                10: 1.5,   // A#
                11: 2.0    // B
            ]

        case .bass:
            // G2 (MIDI 43) is on the bottom line of bass clef
            referenceNote = 43  // G2
            referencePosition = 4  // Bottom line
            noteToStaffPosition = [
                0: -2.0,   // C (below G)
                1: -2.0,   // C#
                2: -1.5,   // D
                3: -1.5,   // D#
                4: -1.0,   // E
                5: -0.5,   // F
                6: -0.5,   // F#
                7: 0.0,    // G (reference)
                8: 0.0,    // G#
                9: 0.5,    // A
                10: 0.5,   // A#
                11: 1.0    // B
            ]
        }

        // Calculate octave difference
        let octaveDiff = (midiNote / 12) - (referenceNote / 12)
        let noteClass = midiNote % 12
        let refNoteClass = referenceNote % 12

        // Get base position offset for this note class
        let baseOffset = noteToStaffPosition[noteClass] ?? 0
        let refOffset = noteToStaffPosition[refNoteClass] ?? 0

        // Calculate total position (each octave = 3.5 staff positions)
        let position = referencePosition - (baseOffset - refOffset) - (CGFloat(octaveDiff) * 3.5)

        // Calculate Y coordinate
        let y = staffTop + (position * lineSpacing)

        // Check if ledger lines are needed
        let needsLedger = position < 0 || position > 4

        return (y, needsLedger)
    }

    private func getNoteNameFromMidi(_ midiNote: Int) -> String {
        let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let octave = (midiNote / 12) - 1
        let noteIndex = midiNote % 12
        return "\(noteNames[noteIndex])\(octave)"
    }
}

// MARK: - Supporting Types
private enum ClefType {
    case treble
    case bass
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // C major chord in treble clef
        StaffNotationView(midiContent: "MIDI:60,64,67:2.0s")
            .frame(height: 120)
            .padding()
            .background(Color.gray.opacity(0.1))

        // Low notes in bass clef
        StaffNotationView(midiContent: "MIDI:36,40,43:2.0s")
            .frame(height: 120)
            .padding()
            .background(Color.gray.opacity(0.1))

        // Wide range (would need grand staff in future)
        StaffNotationView(midiNotes: [48, 60, 72], showLabels: true)
            .frame(height: 120)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}