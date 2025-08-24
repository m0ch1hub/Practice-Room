import Foundation

struct MajorChordExampleLibrary {
    
    static func getAllExamples() -> [MusicTheoryExample] {
        return [
            // BEGINNER LEVEL EXAMPLES
            basicDefinition(),
            simpleExplanation(),
            visualBuilding(),
            soundCharacteristics(),
            
            // INTERMEDIATE LEVEL EXAMPLES
            intervalConstruction(),
            scaleRelationship(),
            inversionIntroduction(),
            functionInKeys(),
            
            // ADVANCED LEVEL EXAMPLES
            harmonicSeries(),
            voiceLeadingPrinciples(),
            jazzExtensions(),
            
            // PRACTICAL APPLICATION EXAMPLES
            pianoFingeringGuide(),
            guitarChordShapes(),
            recognitionTraining(),
            
            // CONTEXTUAL EXAMPLES
            classicalUsage(),
            jazzHarmonyContext(),
            popMusicApplication(),
            
            // COMPARISON EXAMPLES
            majorVsMinor(),
            majorVsDiminished(),
            
            // CONSTRUCTION FOCUSED
            stepByStepBuilding(),
            intervalMath(),
            noteNamingConventions()
        ]
    }
    
    // MARK: - Beginner Level Examples
    
    static func basicDefinition() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "What is a Major Chord? - Perfect Definition",
            content: """
{
  "sections": [
    {
      "type": "text",
      "content": "**What is a Major Chord?**\\n\\nAt its core, a chord just means playing several notes at once. A major chord specifically has a sound that people often describe as happy, bright, or stable.\\n\\nA major chord consists of three notes. Here's how it's built:"
    },
    {
      "type": "text", 
      "content": "**1. The Root Note**\\nFirst, we have our root note, which in this case is C."
    },
    {
      "type": "audio",
      "content": "MIDI:60:1.0s",
      "displayText": "Play Root Note (C)"
    },
    {
      "type": "text",
      "content": "**2. The Major Third**\\nThen we add a major third above C. The major third is four half steps above the root note."
    },
    {
      "type": "audio",
      "content": "MIDI:60,64:1.5s",
      "displayText": "Play Major Third (C-E)"
    },
    {
      "type": "text",
      "content": "**3. The Perfect Fifth**\\nFinally, the last note to complete this chord is a perfect fifth above C, which is G. This is seven half steps above the root note."
    },
    {
      "type": "audio",
      "content": "MIDI:60,67:1.5s", 
      "displayText": "Play Perfect Fifth (C-G)"
    },
    {
      "type": "text",
      "content": "**The Complete Chord**\\nThat's your major chord - three notes (C, E, G) that create that bright, stable sound we recognize everywhere in music."
    },
    {
      "type": "audio",
      "content": "MIDI:60,64,67:2.0s",
      "displayText": "Play Complete C Major"
    }
  ],
  "examples": [
    {
      "type": "chord",
      "content": "MIDI:60,64,67:1.5s",
      "displayText": "Play C Major Chord"
    },
    {
      "type": "note", 
      "content": "MIDI:60:1.0s",
      "displayText": "Play Root Note (C)"
    },
    {
      "type": "interval",
      "content": "MIDI:60,64:1.5s",
      "displayText": "Play Major Third (C-E)"
    },
    {
      "type": "interval",
      "content": "MIDI:60,67:1.5s", 
      "displayText": "Play Perfect Fifth (C-G)"
    },
    {
      "type": "chord",
      "content": "MIDI:60,64,67:2.0s",
      "displayText": "Play Complete C Major"
    }
  ]
}
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .simple,
                musicalContext: .general,
                focus: .definition,
                prerequisites: [],
                targetAudience: ["absolute_beginner", "non_musician"],
                estimatedReadTime: 45
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play C Major Chord"),
                MusicalExample(type: .note, content: "C", displayText: "Play Root (C)"),
                MusicalExample(type: .interval, content: "C E", displayText: "Play Major Third (C-E)"),
                MusicalExample(type: .interval, content: "C G", displayText: "Play Perfect Fifth (C-G)"),
                MusicalExample(type: .chord, content: "C major", displayText: "Play Complete C Major")
            ],
            tags: ["beginner", "definition", "basic", "introduction", "what_is", "perfect_response"]
        )
    }
    
    static func simpleExplanation() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chords Explained Simply",
            content: """
**Understanding Major Chords**

Imagine you're baking a cake. A major chord is like a simple recipe with just three ingredients that always work together perfectly.

**The Recipe for Any Major Chord:**
1. Start with any note (this is your "root")
2. Skip one note and take the next one (this is your "third")
3. Skip one more note and take the next one (this is your "fifth")

**Real Example: Building D Major**
- Start with D (root)
- Skip E, land on F# (third) 
- Skip G, land on A (fifth)
- Result: D + F# + A = D major chord!

**The Magic**
When you play these three notes together, they create harmony - multiple sounds that blend into something beautiful and complete. Major chords sound "resolved" and "happy" to most people's ears.

**Try This**
Pick any note on a piano or guitar, follow the recipe above, and you'll create a major chord. It works every time!
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .simple,
                musicalContext: .general,
                focus: .construction,
                prerequisites: [],
                targetAudience: ["beginner", "visual_learner"],
                estimatedReadTime: 60
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "D major", displayText: "Play D Major Chord"),
                MusicalExample(type: .sequence, content: "D-F#-A", displayText: "Play D Major Notes Separately")
            ],
            tags: ["simple", "construction", "recipe", "building", "how_to"]
        )
    }
    
    // MARK: - Intermediate Level Examples
    
    static func intervalConstruction() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chord Construction Using Intervals",
            content: """
**Building Major Chords with Intervals**

A **major chord** is constructed using specific interval relationships that create its characteristic sound.

**The Interval Formula: Root + Major Third + Perfect Fifth**

**Major Third Interval**
- Distance: 4 semitones (half steps) above the root
- Sound: Bright, optimistic quality
- Example: C to E is a major third

**Perfect Fifth Interval**  
- Distance: 7 semitones above the root
- Sound: Stable, complete feeling
- Example: C to G is a perfect fifth

**Step-by-Step Construction:**

1. **Choose your root note** (example: F)
2. **Add the major third:** Count up 4 semitones
   - F → F# → G → G# → A (A is the major third)
3. **Add the perfect fifth:** Count up 7 semitones from root
   - F → F# → G → G# → A → A# → B → C (C is the perfect fifth)

**Result: F Major = F + A + C**

This formula works for any root note, making it easy to build major chords in all 12 keys.

**Why These Intervals?**
The major third creates the "major" quality, while the perfect fifth provides harmonic stability. This combination has been fundamental to Western music for centuries.
""",
            metadata: ExampleMetadata(
                difficulty: .intermediate,
                teachingStyle: .technical,
                musicalContext: .general,
                focus: .construction,
                prerequisites: ["intervals", "semitones"],
                targetAudience: ["music_student", "theory_learner"],
                estimatedReadTime: 90
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "F major", displayText: "Play F Major Chord"),
                MusicalExample(type: .interval, content: "F A", displayText: "Play Major Third (F-A)"),
                MusicalExample(type: .interval, content: "F C", displayText: "Play Perfect Fifth (F-C)")
            ],
            tags: ["intervals", "construction", "semitones", "technical", "formula"]
        )
    }
    
    // MARK: - Advanced Level Examples
    
    static func harmonicSeries() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chords and the Harmonic Series",
            content: """
**The Physics Behind Major Chords**

Major chords sound "natural" because they closely mirror the **harmonic series** - the natural overtones produced by any vibrating string or air column.

**The Harmonic Series from C:**
1. C (fundamental)
2. C (octave)  
3. G (perfect fifth)
4. C (two octaves)
5. E (major third)
6. G (perfect fifth + octave)

**Natural Resonance**
Notice that the first few overtones spell out a C major chord: **C-E-G**. This is why major chords sound "resolved" and "stable" to human ears - they align with the natural physics of sound.

**Implications for Harmony:**
- Major chords require less cognitive processing to understand
- They blend naturally with the harmonic series of the root note
- This explains their prevalence across cultures and musical styles
- The strength of harmonic series relationships affects chord stability

**Voice Leading Considerations**
Understanding harmonic series helps explain why certain voicings and inversions of major chords sound more or less stable, and guides advanced harmonic progressions.

**Historical Context**
Composers like Bach intuited these relationships centuries before the physics was understood, creating music that naturally aligned with harmonic series principles.
""",
            metadata: ExampleMetadata(
                difficulty: .advanced,
                teachingStyle: .conceptual,
                musicalContext: .classical,
                focus: .theory,
                prerequisites: ["harmonic_series", "overtones", "physics"],
                targetAudience: ["advanced_student", "music_theory_student"],
                estimatedReadTime: 120
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play C Major (Natural Harmonics)"),
                MusicalExample(type: .sequence, content: "C-C-G-C-E-G", displayText: "Play Harmonic Series Pattern")
            ],
            tags: ["physics", "harmonic_series", "advanced", "theory", "natural"]
        )
    }
    
    // MARK: - Contextual Examples
    
    static func jazzHarmonyContext() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chords in Jazz Harmony",
            content: """
**Major Chords in Jazz Context**

In jazz, major chords serve as both harmonic foundations and launching points for complex extensions and alterations.

**Common Jazz Applications:**

**1. Tonic Major Chords (I)**
- Function: Home base, resolution point
- Common extensions: Maj7, Maj9, Maj13
- Example: CMaj7 in key of C major

**2. Subdominant Major Chords (IV)**  
- Function: Departure from tonic, building tension
- Often includes #11 extension
- Example: FMaj7#11 in key of C major

**3. Modal Interchange**
Major chords borrowed from parallel modes:
- bVII (from mixolydian): BbMaj7 in C major
- bIII (from aeolian): EbMaj7 in C major

**Voice Leading in Jazz**
Jazz pianists often voice major chords with:
- Root in bass, extensions in right hand
- Drop-2 and drop-3 voicings
- Rootless voicings for comping

**Relationship to Extensions:**
- Major 7th: Creates dreamy, floating quality
- Major 9th: Adds color without changing function  
- Major 13th: Full, lush sound for final chords

**Common Progressions:**
- I-vi-ii-V: Major chord as tonic resolution
- I-IV-I: Strong modal sound with IV major
""",
            metadata: ExampleMetadata(
                difficulty: .advanced,
                teachingStyle: .technical,
                musicalContext: .jazz,
                focus: .application,
                prerequisites: ["jazz_theory", "chord_extensions", "roman_numerals"],
                targetAudience: ["jazz_student", "pianist", "advanced_player"],
                estimatedReadTime: 100
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "CMaj7", displayText: "Play CMaj7"),
                MusicalExample(type: .chord, content: "FMaj7#11", displayText: "Play FMaj7#11"),
                MusicalExample(type: .chordProgression, content: "CMaj7-Am7-Dm7-G7", displayText: "Play I-vi-ii-V")
            ],
            tags: ["jazz", "extensions", "voicings", "advanced", "modal"]
        )
    }
    
    // MARK: - Comparison Examples
    
    static func majorVsMinor() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major vs Minor Chords: The Essential Difference",
            content: """
**Major vs Minor: One Note Changes Everything**

The difference between major and minor chords is incredibly simple yet profoundly important - just one note!

**The Only Difference: The Third**

**Major Chord Third:**
- Distance from root: Major third (4 semitones)
- Sound: Bright, happy, optimistic
- Example: C major uses E (major third)

**Minor Chord Third:**
- Distance from root: Minor third (3 semitones)  
- Sound: Dark, sad, introspective
- Example: C minor uses Eb (minor third)

**Side-by-Side Comparison:**
- **C Major**: C + E + G (bright, happy)
- **C Minor**: C + Eb + G (dark, sad)

**Emotional Impact**
This single note change completely transforms the emotional character:
- Major: celebrations, victories, joy, confidence
- Minor: reflection, melancholy, mystery, drama

**In Real Music**
- "Happy Birthday" - major chords create celebratory feel
- "Greensleeves" - minor chords create wistful, longing atmosphere

**Practice Tip**
Play the same chord progression in major, then minor. Notice how the entire mood shifts with just that one note difference per chord.

**Both Are Essential**
Neither is "better" - they serve different emotional and musical purposes. Great songs often move between both.
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .comparison,
                musicalContext: .general,
                focus: .comparison,
                prerequisites: ["basic_chords"],
                targetAudience: ["beginner", "general_learner"],
                estimatedReadTime: 75
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play C Major (Happy)"),
                MusicalExample(type: .chord, content: "C minor", displayText: "Play C Minor (Sad)"),
                MusicalExample(type: .chordProgression, content: "C-F-G-C", displayText: "Major Progression"),
                MusicalExample(type: .chordProgression, content: "Cm-Fm-G-Cm", displayText: "Minor Progression")
            ],
            tags: ["comparison", "minor", "emotion", "difference", "beginner"]
        )
    }
    
    // Add more examples as needed...
    static func visualBuilding() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Building Major Chords Visually",
            content: """
**Visual Guide to Major Chords**

Think of major chords like a simple pattern you can see and feel.

**The Pattern: Skip One, Take One**
Starting from any note, follow this visual pattern:
1. **Root** (starting point)
2. **Skip** the very next note
3. **Take** the following note (this is your third)
4. **Skip** the next note  
5. **Take** the following note (this is your fifth)

**On Piano Keys (White Keys Example):**
For C major: C (root) → skip D → E (third) → skip F → G (fifth)

**The Shape**
Major chords always have this "skip-take-skip-take" pattern, creating a consistent visual shape on any instrument.

**Memory Trick**
Every major chord looks like a "staircase with missing steps" - you're always skipping one step and taking the next.
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .visual,
                musicalContext: .general,
                focus: .construction,
                prerequisites: [],
                targetAudience: ["visual_learner", "piano_beginner"],
                estimatedReadTime: 30
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play C Major Pattern")
            ],
            tags: ["visual", "pattern", "piano", "shape", "memory"]
        )
    }
    
    static func soundCharacteristics() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "The Sound of Major Chords",
            content: """
**What Makes Major Chords Sound "Happy"?**

Major chords have a distinctive bright, uplifting quality that most people describe as "happy" or "positive."

**Sound Characteristics:**
- **Bright**: The major third interval creates brightness
- **Stable**: The perfect fifth provides resolution and completeness  
- **Open**: The spacing between notes creates an "airy" feeling
- **Resolved**: Sounds like it doesn't need to go anywhere else

**Why Our Ears Hear "Happy":**
The major third interval has a frequency ratio that our brains interpret as consonant and pleasant. This isn't cultural - it's based on the physics of sound waves.

**Compare the Feelings:**
- Major chord: sunshine, celebration, triumph, joy
- Minor chord: rain, reflection, mystery, sadness

**In Different Contexts:**
- **Soft major chord**: peaceful, calm, content
- **Loud major chord**: triumphant, powerful, heroic
- **High major chord**: bright, sparkling, light
- **Low major chord**: warm, full, grounding
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .auditory,
                musicalContext: .general,
                focus: .recognition,
                prerequisites: [],
                targetAudience: ["ear_training", "beginner"],
                estimatedReadTime: 45
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play Bright C Major"),
                MusicalExample(type: .chord, content: "F major", displayText: "Play Warm F Major"),
                MusicalExample(type: .chord, content: "G major", displayText: "Play Triumphant G Major")
            ],
            tags: ["sound", "emotion", "bright", "happy", "listening"]
        )
    }
    
    // Placeholder implementations for remaining examples
    static func scaleRelationship() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chords and Scale Relationships",
            content: """
**Major Chords Within Major Scales**

Major chords naturally occur at specific positions within major scales, creating a systematic foundation for understanding harmony.

**The I, IV, V Pattern**

In any major scale, major chords appear on:
- **I (Tonic)**: The home chord, built on the 1st scale degree
- **IV (Subdominant)**: Built on the 4th scale degree  
- **V (Dominant)**: Built on the 5th scale degree

**Example in C Major Scale:**
- Scale notes: C-D-E-F-G-A-B
- **I chord**: C major (C-E-G)
- **IV chord**: F major (F-A-C) 
- **V chord**: G major (G-B-D)

**Why These Work Together**

These three major chords share notes with the underlying scale:
- All chord tones come from the same 7-note scale
- They create smooth voice leading between chords
- They establish and maintain the key center

**Common Progressions**
- I-IV-V-I: The most fundamental progression in Western music
- I-V-vi-IV: Popular in contemporary music
- I-IV-I: Simple but effective movement

**Scale Degree Relationships**
Each major chord serves a harmonic function based on its scale position, creating predictable patterns that work across all keys.
""",
            metadata: ExampleMetadata(
                difficulty: .intermediate,
                teachingStyle: .conceptual,
                musicalContext: .general,
                focus: .theory,
                prerequisites: ["major_scales", "scale_degrees"],
                targetAudience: ["theory_student", "chord_progression_learner"],
                estimatedReadTime: 90
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Play I Chord (C)"),
                MusicalExample(type: .chord, content: "F major", displayText: "Play IV Chord (F)"),
                MusicalExample(type: .chord, content: "G major", displayText: "Play V Chord (G)"),
                MusicalExample(type: .chordProgression, content: "C-F-G-C", displayText: "Play I-IV-V-I")
            ],
            tags: ["scales", "theory", "progressions", "I-IV-V", "harmony"]
        )
    }
    
    static func inversionIntroduction() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chord Inversions Explained",
            content: """
**Understanding Chord Inversions**

A chord **inversion** simply means changing which note is in the bass (lowest position). Major chords have three possible positions.

**The Three Positions of C Major:**

**Root Position**: C-E-G
- C is in the bass
- The "normal" chord position
- Strongest, most stable sound

**First Inversion**: E-G-C  
- E (the third) is in the bass
- Lighter, more flowing sound
- Good for smooth bass lines

**Second Inversion**: G-C-E
- G (the fifth) is in the bass 
- Less stable, wants to resolve
- Often used as passing chord

**Why Use Inversions?**

**Smooth Bass Movement**
Inversions create smoother bass lines instead of jumping around:
- C major (root) → F major (1st inv.) creates C-A bass movement
- Much smoother than C-F jump

**Voice Leading**
Inversions help voices move in smaller steps, creating more elegant progressions.

**Different Characters**
- Root position: strong, grounded
- First inversion: gentle, flowing  
- Second inversion: transitional, unstable

**Notation**
Roman numeral analysis shows inversions with numbers:
- I = root position
- I⁶ = first inversion  
- I⁶⁴ = second inversion
""",
            metadata: ExampleMetadata(
                difficulty: .intermediate,
                teachingStyle: .technical,
                musicalContext: .general,
                focus: .application,
                prerequisites: ["basic_chords", "bass_notes"],
                targetAudience: ["piano_student", "theory_learner"],
                estimatedReadTime: 85
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "C Major (Root Position)"),
                MusicalExample(type: .chord, content: "C major/E", displayText: "C Major (1st Inversion)"),
                MusicalExample(type: .chord, content: "C major/G", displayText: "C Major (2nd Inversion)")
            ],
            tags: ["inversions", "voice_leading", "bass", "positions", "harmony"]
        )
    }
    
    static func functionInKeys() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .intermediate, teachingStyle: .technical, musicalContext: .general, focus: .theory, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func voiceLeadingPrinciples() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .advanced, teachingStyle: .technical, musicalContext: .classical, focus: .application, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func jazzExtensions() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .advanced, teachingStyle: .technical, musicalContext: .jazz, focus: .application, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func pianoFingeringGuide() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Piano Fingering for Major Chords",
            content: """
**Proper Fingering for Major Chords**

Using correct fingering makes major chords easier to play and creates better hand position for chord progressions.

**Right Hand Fingerings:**

**C Major: 1-3-5 (Thumb-Middle-Pinky)**
- C (thumb), E (middle finger), G (pinky)
- Most natural and comfortable fingering
- Foundation pattern for other major chords

**F Major: 1-2-5 (Thumb-Index-Pinky)**  
- F (thumb), A (index), C (pinky)
- Index finger handles the black key comfortably

**G Major: 1-2-4 (Thumb-Index-Ring)**
- G (thumb), B (index), D (ring finger)
- Avoids using pinky on D for better hand position

**Left Hand Bass Notes:**
- Use thumb (1) or pinky (5) for single bass notes
- For full left-hand chords, reverse the fingering (5-3-1)

**Practice Tips:**

**1. Curved Fingers**
- Keep fingers curved like holding a small ball
- Fingertips contact keys, not finger pads

**2. Relaxed Wrist**
- Wrist should be level with hands, not dropped
- No tension in shoulders or arms

**3. Smooth Transitions**
- Practice moving between C-F-G-C using proper fingerings
- Minimize hand movement and finger lifting

**Common Mistakes to Avoid:**
- Using 1-2-3 for everything (creates awkward positions)
- Flat fingers or collapsed knuckles
- Tense shoulders or rigid wrists
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .practical,
                musicalContext: .general,
                focus: .application,
                prerequisites: ["piano_basics"],
                targetAudience: ["piano_student", "beginner_pianist"],
                estimatedReadTime: 75
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "C Major (1-3-5)"),
                MusicalExample(type: .chord, content: "F major", displayText: "F Major (1-2-5)"),
                MusicalExample(type: .chord, content: "G major", displayText: "G Major (1-2-4)"),
                MusicalExample(type: .chordProgression, content: "C-F-G-C", displayText: "Practice Progression")
            ],
            tags: ["piano", "fingering", "technique", "practice", "hand_position"]
        )
    }
    
    static func guitarChordShapes() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .beginner, teachingStyle: .practical, musicalContext: .general, focus: .application, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func recognitionTraining() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Training Your Ear for Major Chords",
            content: """
**Developing Major Chord Recognition**

Training your ear to instantly identify major chords is essential for musicians. Here's how to develop this skill systematically.

**Step 1: Learn the "Major Sound"**

**Characteristics to Listen For:**
- **Bright, happy quality** - sounds "resolved" and complete
- **Stable feeling** - doesn't need to go anywhere else  
- **Open sound** - spacious and airy
- **Confident character** - sounds strong and positive

**Step 2: Compare and Contrast**

**Major vs Minor (Most Important)**
- Play C major, then C minor
- Notice how major sounds "bright" and minor sounds "dark"
- Practice switching back and forth until the difference is obvious

**Major vs Diminished**  
- Major: stable and resolved
- Diminished: tense and wanting to resolve

**Step 3: Recognition Exercises**

**Exercise 1: Blind Identification**
- Have someone play random major and minor chords
- Identify which is which without looking
- Start with obvious examples, gradually make them subtler

**Exercise 2: Song Recognition**
- Listen to familiar songs and identify when major chords occur
- Notice how major chords often appear in choruses and happy sections

**Exercise 3: Interval Training**
- Focus on hearing the major third interval within the chord
- This is the note that makes it "major"

**Practice Tips:**
- Start with clear, simple chord voicings
- Use different instruments to hear various timbres
- Practice daily in short 5-10 minute sessions
- Trust your emotional response - major chords feel "happy"
""",
            metadata: ExampleMetadata(
                difficulty: .intermediate,
                teachingStyle: .auditory,
                musicalContext: .general,
                focus: .recognition,
                prerequisites: ["basic_listening"],
                targetAudience: ["ear_training", "music_student", "developing_musician"],
                estimatedReadTime: 90
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "C major", displayText: "Reference: C Major"),
                MusicalExample(type: .chord, content: "C minor", displayText: "Compare: C Minor"),
                MusicalExample(type: .chord, content: "F major", displayText: "Test: F Major"),
                MusicalExample(type: .chord, content: "G major", displayText: "Test: G Major")
            ],
            tags: ["ear_training", "recognition", "listening", "identification", "practice"]
        )
    }
    
    static func classicalUsage() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .intermediate, teachingStyle: .conceptual, musicalContext: .classical, focus: .application, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func popMusicApplication() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Major Chords in Pop Music",
            content: """
**Major Chords: The Backbone of Pop Music**

Major chords dominate popular music because they create the uplifting, catchy sound that connects with listeners.

**The "Four Chords" Phenomenon**

Countless pop hits use the same four-chord progression:
- **vi-IV-I-V** (in key of C: Am-F-C-G)
- Examples: "Don't Stop Believin'", "Let It Be", "Someone Like You"
- Major chords (F, C, G) provide the bright, singable foundation

**Why Pop Loves Major Chords:**

**1. Emotional Appeal**
- Create feelings of joy, triumph, and hope
- Perfect for uplifting choruses and memorable hooks

**2. Vocal Friendliness**  
- Major chords support clear, strong melodies
- Easy for audiences to sing along

**3. Universal Recognition**
- Cross-cultural appeal
- Instantly recognizable and comforting

**Common Pop Chord Progressions:**
- **I-V-vi-IV**: "With or Without You", "Don't Stop Believin'"
- **vi-IV-I-V**: "Someone Like You", "Let It Be"
- **I-vi-IV-V**: "Blue Moon", "Heart and Soul"

**Modern Pop Techniques:**
- Add 7ths and 9ths for sophistication (Cmaj7, Fmaj9)
- Use inversions for smoother bass lines
- Layer with synths and production for fuller sound

**Artists to Study:**
Beatles, Taylor Swift, Ed Sheeran, and Coldplay all masterfully use major chord progressions.
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .practical,
                musicalContext: .pop,
                focus: .application,
                prerequisites: ["basic_chords"],
                targetAudience: ["songwriter", "pop_musician", "guitar_player"],
                estimatedReadTime: 80
            ),
            musicalExamples: [
                MusicalExample(type: .chordProgression, content: "Am-F-C-G", displayText: "Play vi-IV-I-V"),
                MusicalExample(type: .chordProgression, content: "C-G-Am-F", displayText: "Play I-V-vi-IV"),
                MusicalExample(type: .chord, content: "C major", displayText: "Play Pop C Major")
            ],
            tags: ["pop_music", "songwriting", "progressions", "four_chords", "contemporary"]
        )
    }
    
    static func majorVsDiminished() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .intermediate, teachingStyle: .comparison, musicalContext: .general, focus: .comparison, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func stepByStepBuilding() -> MusicTheoryExample {
        return MusicTheoryExample(
            concept: "major_chord",
            title: "Step-by-Step Major Chord Building",
            content: """
**Building Your First Major Chord**

Let's build a major chord together, step by step. We'll use A major as our example.

**Step 1: Choose Your Root**
- Pick any note to be your starting point
- This note gives the chord its name
- **Our choice**: A (this will make an A major chord)

**Step 2: Find the Major Third**
- Count up 4 half-steps from your root
- **From A**: A→A#→B→C→C# (4 steps)
- **Result**: C# is our major third

**Step 3: Find the Perfect Fifth** 
- Count up 7 half-steps from your root
- **From A**: A→A#→B→C→C#→D→D#→E (7 steps)
- **Result**: E is our perfect fifth

**Step 4: Put It Together**
- **A major chord** = A + C# + E
- Play all three notes at the same time
- Listen to that bright, happy major chord sound!

**Practice This Method**
Try building these major chords using the same steps:
1. **D major**: D + ? + ?
2. **G major**: G + ? + ?
3. **E major**: E + ? + ?

**Quick Check**
Every major chord should sound bright and resolved. If it sounds dark or tense, double-check your counting!

**Remember the Formula**
Root + 4 half-steps + 7 half-steps = Any major chord
""",
            metadata: ExampleMetadata(
                difficulty: .beginner,
                teachingStyle: .practical,
                musicalContext: .general,
                focus: .construction,
                prerequisites: ["half_steps"],
                targetAudience: ["absolute_beginner", "self_learner"],
                estimatedReadTime: 70
            ),
            musicalExamples: [
                MusicalExample(type: .chord, content: "A major", displayText: "Play A Major Result"),
                MusicalExample(type: .note, content: "A", displayText: "Step 1: Root (A)"),
                MusicalExample(type: .note, content: "C#", displayText: "Step 2: Major Third (C#)"),
                MusicalExample(type: .note, content: "E", displayText: "Step 3: Perfect Fifth (E)"),
                MusicalExample(type: .sequence, content: "A-C#-E", displayText: "Play Notes Separately")
            ],
            tags: ["tutorial", "step_by_step", "building", "beginner", "practice"]
        )
    }
    
    static func intervalMath() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .intermediate, teachingStyle: .technical, musicalContext: .general, focus: .construction, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
    
    static func noteNamingConventions() -> MusicTheoryExample { 
        return MusicTheoryExample(concept: "major_chord", title: "Placeholder", content: "Content", metadata: ExampleMetadata(difficulty: .beginner, teachingStyle: .technical, musicalContext: .general, focus: .theory, prerequisites: [], targetAudience: [], estimatedReadTime: 60))
    }
}