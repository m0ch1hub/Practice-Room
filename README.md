# Practice Room Chat

An iOS music theory tutoring chat application powered by a fine-tuned Google Vertex AI Gemini model with real-time audio playback.

## Features

- **Fine-tuned AI Model**: Custom-trained Gemini model specialized for music theory education
- **Real-time Audio Playback**: Instant MIDI-based sound generation for musical examples
- **Swift/SwiftUI Interface**: Native iOS experience with clean, responsive design
- **Structured Response Parsing**: Smart extraction of musical examples from AI responses

## Technical Architecture

### AI Service (`ChatService.swift`)
- Google Vertex AI integration with OAuth authentication
- Fine-tuned Gemini model endpoint: `gold-major-checkpoint-10-6306300618155753472`
- Structured response parsing for text and audio examples
- Error handling with user-friendly fallbacks

### Audio Engine (`SoundEngine.swift`)
- AVAudioEngine-based MIDI playback
- Support for notes, intervals, chords, scales, and progressions
- Real-time synthesis without external sample libraries

### Models
- `ChatMessage`: Message container with embedded musical examples
- `MusicalExample`: Typed audio examples (note, chord, scale, etc.)
- `ServiceAccountAuth`: Simplified OAuth token management

## Getting Started

1. Open `PracticeRoomChat.xcodeproj` in Xcode
2. Build and run the project
3. Start chatting about music theory topics

## Usage Examples

Ask questions like:
- "What is a C major chord?"
- "Explain the circle of fifths"
- "How do you build a minor scale?"
- "What's a dominant seventh chord?"

The AI will respond with explanations and playable audio examples.