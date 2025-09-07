# Training Data Best Practices for Music Theory AI

## Core Principles

### 1. Key Consistency
- **Use C Major for 90%+ of examples** - Creates consistent reference point for learning
- Only introduce other keys when demonstrating transposition or key-specific concepts
- This constraint forces focus on relationships rather than memorization

### 2. Simplicity First
- Keep explanations conversational, not academic
- One concept per response
- Avoid technical jargon unless necessary
- Build complexity gradually within multi-turn conversations

## MIDI Demonstration Guidelines

### Timing Standards
```
Single Notes: 0.6-0.8s (quick identification)
Intervals: 1.5-2.0s (relationship recognition)  
Full Chords: 2.0-2.5s (harmonic appreciation)
Progressions: 1.8s per chord, 2.5s for final resolution
```

### Sequencing Rules

#### Use Pipe Separator (|) For:
- **Direct comparisons** (major vs minor)
- **Progressive building** (C → C+E → C+E+G)
- **Before/after demonstrations**
- **Maximum 4 segments per sequence**

#### Use Separate AUDIO Tags For:
- **Different concepts within same response**
- **When explanation needed between sounds**
- **Building anticipation or creating pause**

### MOMENT Tag Usage
- **New MOMENT = New idea or perspective**
- Use to separate:
  - Setup from demonstration
  - Multiple examples of same concept
  - Comparison setups
- Don't overuse - 2-3 MOMENTS per response maximum

## Pedagogical Patterns

### 1. The Build Pattern
```
[AUDIO:MIDI:60:0.8s:Root - C]
[AUDIO:MIDI:60,64:1.5s:Add Major Third]
[AUDIO:MIDI:60,64,67:2.5s:Complete Triad]
```
**Use for**: Chord construction, interval stacking

### 2. The Comparison Pattern
```
[AUDIO:MIDI:60,64,67|60,63,67:2.0s,2.0s:Major then Minor]
```
**Use for**: Quality differences, emotional contrasts

### 3. The Context Pattern
```
[AUDIO:MIDI:60,64,67:2.0s:Isolated Chord]
[AUDIO:MIDI:60,64,67|67,71,74|60,64,67:1.8s,1.8s,2.5s:Chord in Progression]
```
**Use for**: Showing function, demonstrating resolution

### 4. The Focus Pattern
```
[AUDIO:MIDI:60,64:2.0s:Just the Third]
[AUDIO:MIDI:60,64,67:2.0s:Third in Context]
```
**Use for**: Isolating specific intervals, highlighting changes

## What Makes MIDI "Meaningful"

### ✅ DO: Demonstrate Purpose
- Show WHY something sounds happy/sad/tense
- Demonstrate resolution and movement
- Use repetition with variation
- Create musical sentences, not just words

### ❌ DON'T: Just Play Notes
- Avoid playing full chord without context
- Don't use same timing for everything
- Skip unnecessary octave jumps
- Avoid rapid-fire examples without processing time

## Response Structure Template

```markdown
[Opening statement - what we're exploring]

[MOMENT]

[Setup or context for what they're about to hear]
[AUDIO:MIDI:...:First demonstration]

[Brief explanation of what they just heard]
[AUDIO:MIDI:...:Variation or comparison]

[MOMENT] (only if shifting to new aspect)

[Conclusion tying it together]
```

## Common Improvements Needed

### Before: Static Demonstration
```json
"Here's C major: [AUDIO:MIDI:60,64,67:2.0s:C Major]"
```

### After: Progressive Understanding
```json
"Let's build C major from its foundation:
[MOMENT]
Start with C: [AUDIO:MIDI:60:0.8s:Root]
Add the bright major third: [AUDIO:MIDI:60,64:1.5s:C + E]
Complete with the fifth: [AUDIO:MIDI:60,64,67:2.5s:Full C Major]"
```

### Before: Rushed Comparison
```json
"[AUDIO:MIDI:60,64,67|60,63,67|60,63,66|60,64,68:2.0s,2.0s,2.0s,2.0s:All chord types]"
```

### After: Thoughtful Contrast
```json
"[MOMENT]
C major - our reference: [AUDIO:MIDI:60,64,67:2.0s:Major - Bright]
Now minor - feel the shift: [AUDIO:MIDI:60,63,67:2.0s:Minor - Dark]
[MOMENT]
Back to major: [AUDIO:MIDI:60,64,67:1.5s:Major Again]
Diminished creates tension: [AUDIO:MIDI:60,63,66:2.0s:Diminished - Unstable]"
```

## Quality Checklist

Before adding any training example, verify:

- [ ] MIDI demonstrates the concept, not just plays it
- [ ] Timing serves pedagogical purpose
- [ ] Uses C major unless specifically needed otherwise
- [ ] Includes comparison or context when relevant
- [ ] MOMENT tags separate distinct ideas
- [ ] Audio descriptions are meaningful ("Bright Interval" not just "C-E")
- [ ] Response builds understanding progressively
- [ ] No unnecessary complexity or showing off

## Special Cases

### Multi-turn Conversations
- First turn: Introduce concept simply
- Follow-ups: Add layers of understanding
- Use previous context to build deeper insights
- Reference earlier audio examples when relevant

### Extended Chords
- Always show base triad first
- Add extension as separate step
- Demonstrate resolution when applicable
- Keep in C major family (Cmaj7, C7, etc.)

### Inversions
- Use same octave range for all positions
- Show voice movement between inversions
- Explain why inversions matter (voice leading, bass lines)

## Final Note

The goal is not to create music theory robots but to help people HEAR and UNDERSTAND musical relationships. Every MIDI example should reveal something about how music works, not just demonstrate that we know the right notes.

Remember: **Simple + Purposeful > Complex + Impressive**