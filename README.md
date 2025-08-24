# Music Theory Chat

An intelligent music theory tutor chat application with real-time sound playback capabilities.

## Features

### Core Functionality
- **AI-Powered Music Theory Tutor**: Uses OpenAI GPT-4 for intelligent music theory explanations
- **Real-Time Sound Generation**: Instant playback of musical examples using Tone.js
- **Smart Music Library**: Non-AI based, efficient music theory engine for fast computation

### Musical Capabilities
- **Notes**: Individual note playback with proper pitch and octave
- **Intervals**: Play two notes simultaneously or sequentially 
- **Chords**: Full chord voicings with multiple qualities (major, minor, 7th, etc.)
- **Scales**: All standard scales (major, minor, modes, pentatonic, blues, etc.)
- **Chord Progressions**: Sequential chord playback with proper timing

### Technical Architecture

#### Music Theory Engine (`/src/lib/music-theory.ts`)
- Pitch class integer arithmetic (0-11) for fast calculations
- Caching system for scales and chords
- Transposition algorithms
- Interval calculation
- Chord inversions
- Support for 30+ chord types and 13+ scale types

#### Sound Engine (`/src/lib/sound-engine.ts`)
- Built on Tone.js for cross-platform Web Audio
- Polyphonic synthesis with customizable waveforms
- Real-time sound generation (no sample libraries needed)
- Arpeggio patterns
- Volume control

#### AI Integration
- Structured prompt engineering for musical context
- Pattern-based example extraction
- Cost-optimized with GPT-4o-mini
- Musical example tagging system

## Getting Started

```bash
# Install dependencies
npm install

# Run development server
./node_modules/.bin/next dev
```

Open [http://localhost:3000](http://localhost:3000) to use the app.

## Usage Examples

Ask the chat:
- "What is a major scale?"
- "Explain the ii-V-I progression"
- "What's the difference between major and minor chords?"
- "How do intervals work?"
- "Show me a blues scale in A"

The AI will provide explanations with playable musical examples that appear as buttons in the chat.

## Key Design Decisions

1. **Real-time Synthesis over Samples**: Unlimited flexibility for any musical combination
2. **Non-AI Music Engine**: Fast, deterministic, and cost-effective for core music operations
3. **Functional Architecture**: Immutable data structures for predictable behavior
4. **Smart Caching**: Pre-computed common scales and chords for performance

## Future Enhancements

- Voice leading optimization
- MIDI export functionality
- Rhythm pattern library
- Ear training exercises
- Musical notation display
- Multi-track playback
- Custom synthesizer presets