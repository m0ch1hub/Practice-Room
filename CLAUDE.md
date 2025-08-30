# Practice Room Chat - Claude Instructions

## Voice Mode Settings
- **Auto-activate voice mode**: When user says "turn on voice mode", automatically activate voice mode
- **Always set wait_for_response=false**: Never wait for voice responses, allow text replies
- **Voice mode trigger**: Any mention of "turn on voice mode" should immediately activate voice mode

## Project Context
- iOS SwiftUI music theory chat app
- Features audio playback of musical examples (chords, scales, progressions)
- Backend returns responses in various formats (sometimes JSON, sometimes plain text)

## Training Data Guidelines
- **Response Style**: Use exploratory, conversational approach rather than formal lesson structure
- **Building on Material**: Responses should build on previous concepts (e.g., "Now if we take this interval and flip it...")
- **Less Formal Teaching**: Avoid overly structured lessons - prefer "let's try this and see what happens" style
- **Audio Examples**: Include progressive audio examples that demonstrate concepts in different contexts
- **Interval Examples**: When explaining intervals, show them in isolation first, then in chord contexts to demonstrate their characteristic sounds