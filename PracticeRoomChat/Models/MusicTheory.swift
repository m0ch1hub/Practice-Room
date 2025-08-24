import Foundation
import AVFoundation

struct Note {
    let pitchClass: Int
    let octave: Int
    let name: String
    let frequency: Double
    let midi: Int
    
    init(name: String, octave: Int = 4) {
        self.name = name
        self.octave = octave
        self.pitchClass = Note.getPitchClass(from: name)
        self.midi = (octave + 1) * 12 + pitchClass
        self.frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }
    
    private static func getPitchClass(from name: String) -> Int {
        let noteNames = ["C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
                        "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8,
                        "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11]
        return noteNames[name.uppercased()] ?? 0
    }
    
    func transposed(by semitones: Int) -> Note {
        let newMidi = midi + semitones
        let newPitchClass = newMidi % 12
        let newOctave = newMidi / 12 - 1
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return Note(name: noteNames[newPitchClass], octave: newOctave)
    }
}

struct Chord {
    let root: Note
    let quality: String
    let notes: [Note]
    let symbol: String
    
    init(root: String, quality: String = "major") {
        self.root = Note(name: root)
        self.quality = quality
        self.symbol = root + Chord.getSymbol(for: quality)
        self.notes = Chord.generateNotes(root: self.root, quality: quality)
    }
    
    private static func getSymbol(for quality: String) -> String {
        let symbols = [
            "major": "",
            "minor": "m",
            "dim": "°",
            "aug": "+",
            "maj7": "maj7",
            "min7": "m7",
            "7": "7",
            "dim7": "°7",
            "sus2": "sus2",
            "sus4": "sus4"
        ]
        return symbols[quality] ?? ""
    }
    
    private static func generateNotes(root: Note, quality: String) -> [Note] {
        let intervals: [String: [Int]] = [
            "major": [0, 4, 7],
            "minor": [0, 3, 7],
            "dim": [0, 3, 6],
            "aug": [0, 4, 8],
            "maj7": [0, 4, 7, 11],
            "min7": [0, 3, 7, 10],
            "7": [0, 4, 7, 10],
            "dim7": [0, 3, 6, 9],
            "sus2": [0, 2, 7],
            "sus4": [0, 5, 7],
            "6": [0, 4, 7, 9],
            "min6": [0, 3, 7, 9],
            "9": [0, 4, 7, 10, 14],
            "min9": [0, 3, 7, 10, 14],
            "maj9": [0, 4, 7, 11, 14],
            "add9": [0, 4, 7, 14]
        ]
        
        let pattern = intervals[quality] ?? intervals["major"]!
        return pattern.map { root.transposed(by: $0) }
    }
}

struct Scale {
    let root: Note
    let type: String
    let notes: [Note]
    
    init(root: String, type: String = "major") {
        self.root = Note(name: root)
        self.type = type
        self.notes = Scale.generateNotes(root: self.root, type: type)
    }
    
    private static func generateNotes(root: Note, type: String) -> [Note] {
        let patterns: [String: [Int]] = [
            "major": [0, 2, 4, 5, 7, 9, 11],
            "minor": [0, 2, 3, 5, 7, 8, 10],
            "dorian": [0, 2, 3, 5, 7, 9, 10],
            "mixolydian": [0, 2, 4, 5, 7, 9, 10],
            "lydian": [0, 2, 4, 6, 7, 9, 11],
            "phrygian": [0, 1, 3, 5, 7, 8, 10],
            "locrian": [0, 1, 3, 5, 6, 8, 10],
            "harmonic minor": [0, 2, 3, 5, 7, 8, 11],
            "melodic minor": [0, 2, 3, 5, 7, 9, 11],
            "pentatonic major": [0, 2, 4, 7, 9],
            "pentatonic minor": [0, 3, 5, 7, 10],
            "blues": [0, 3, 5, 6, 7, 10],
            "chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        ]
        
        let pattern = patterns[type] ?? patterns["major"]!
        return pattern.map { root.transposed(by: $0) }
    }
}

class MusicTheory {
    static let shared = MusicTheory()
    
    private init() {}
    
    func parseChordProgression(_ progression: String) -> [Chord] {
        Logger.shared.info("🎼 PARSING: Chord progression '\(progression)'")
        
        // Handle single chords first
        if let singleChord = parseChord(progression.trimmingCharacters(in: .whitespacesAndNewlines)) {
            Logger.shared.info("🎵 PARSING: Single chord detected: \(singleChord.symbol)")
            return [singleChord]
        }
        
        // Handle multiple chords
        let chordStrings = progression.split { $0 == "-" || $0 == "," || ($0 == " " && !progression.contains("-")) }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let chords = chordStrings.compactMap { chordString in
            parseChord(chordString)
        }
        
        Logger.shared.info("🎵 PARSING: Extracted \(chords.count) chords: \(chords.map { $0.symbol }.joined(separator: ", "))")
        return chords
    }
    
    
    private func parseChord(_ chordString: String) -> Chord? {
        let qualityMap = [
            "m": "minor",
            "maj7": "maj7",
            "m7": "min7",
            "7": "7",
            "dim": "dim",
            "dim7": "dim7",
            "aug": "aug",
            "sus2": "sus2",
            "sus4": "sus4",
            "6": "6",
            "m6": "min6",
            "9": "9",
            "m9": "min9",
            "maj9": "maj9",
            "add9": "add9"
        ]
        
        var root = ""
        var quality = "major"
        
        if chordString.count >= 1 {
            root = String(chordString.prefix(1))
            
            if chordString.count >= 2 && (chordString[chordString.index(after: chordString.startIndex)] == "#" || 
                                          chordString[chordString.index(after: chordString.startIndex)] == "b") {
                root = String(chordString.prefix(2))
            }
            
            let qualityPart = String(chordString.dropFirst(root.count))
            if !qualityPart.isEmpty {
                quality = qualityMap[qualityPart] ?? "major"
            }
        }
        
        return root.isEmpty ? nil : Chord(root: root, quality: quality)
    }
}