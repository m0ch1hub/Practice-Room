import Foundation

struct MajorChordResponses {
    static let perfectResponses: [String: ChatResponse] = [
        "what_is_major_chord": ChatResponse(
            explanation: """
A **major chord** is one of the most essential building blocks in music theory. It creates a bright, happy, and stable sound that forms the foundation of countless songs across all genres.

**Components of a Major Chord**

A major chord consists of three specific notes:

1. **Root** – the starting note that gives the chord its name
2. **Major third** – an interval that is 4 semitones above the root
3. **Perfect fifth** – an interval that is 7 semitones above the root

**Example: C Major Chord**

• Root: C
• Major third: E
• Perfect fifth: G

When played together, these three notes create the characteristic sound of a major chord – harmonious, complete, and uplifting.
""",
            examples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play C Major Chord"),
                MusicalExample(type: .note, content: "C", displayText: "Play Root Note (C)"),
                MusicalExample(type: .note, content: "E", displayText: "Play Major Third (E)"),
                MusicalExample(type: .note, content: "G", displayText: "Play Perfect Fifth (G)"),
                MusicalExample(type: .chordProgression, content: "C-F-G-C", displayText: "Play C-F-G-C Progression")
            ]
        ),
        
        "major_chord_construction": ChatResponse(
            explanation: """
**How to Build a Major Chord**

Building a major chord is straightforward once you understand the interval pattern. Every major chord follows the same formula, regardless of the root note.

**The Major Chord Formula**

1. **Start with the root note** – this becomes your chord's name
2. **Count up 4 semitones** (half steps) to find the major third
3. **Count up 7 semitones** from the root to find the perfect fifth

**Step-by-Step Example: Building F Major**

1. **Root**: F
2. **Major third**: Count F → F# → G → G# → A (4 semitones) = A
3. **Perfect fifth**: Count F → F# → G → G# → A → A# → B → C (7 semitones) = C

Result: **F Major = F + A + C**

This formula works for any root note, making it easy to build major chords in any key.
""",
            examples: [
                MusicalExample(type: .chord, content: "F major", displayText: "Play F Major Chord"),
                MusicalExample(type: .chord, content: "G major", displayText: "Play G Major Chord"),
                MusicalExample(type: .chord, content: "A major", displayText: "Play A Major Chord"),
                MusicalExample(type: .sequence, content: "F-A-C", displayText: "Play F Major Notes Separately")
            ]
        ),
        
        "major_chord_sound": ChatResponse(
            explanation: """
**The Sound of Major Chords**

Major chords are instantly recognizable for their **bright, happy, and stable** character. This distinctive sound comes from the specific mathematical relationships between the notes.

**Why Major Chords Sound "Happy"**

The major third interval (4 semitones) creates a sense of resolution and brightness that our ears interpret as positive and uplifting. This is why major chords dominate:

• **Pop music** – for catchy, upbeat songs
• **Folk music** – for storytelling and sing-alongs  
• **Classical music** – for triumphant and joyful passages
• **Children's songs** – for their simple, cheerful quality

**Comparing Major vs Minor**

The difference between major and minor is just one note – the third:
- **Major third**: bright, happy sound
- **Minor third**: darker, sadder sound

**Examples in Context**

Major chords often appear in sequences that create strong emotional impact.
""",
            examples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play C Major (Bright)"),
                MusicalExample(type: .chord, content: "C minor", displayText: "Compare with C Minor (Dark)"),
                MusicalExample(type: .chordProgression, content: "C-G-Am-F", displayText: "Play Popular vi-IV-I-V Progression"),
                MusicalExample(type: .chordProgression, content: "C-F-G", displayText: "Play Simple I-IV-V Progression")
            ]
        )
    ]
}

struct ChatResponse {
    let explanation: String
    let examples: [MusicalExample]
}