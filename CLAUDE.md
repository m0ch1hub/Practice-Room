# Practice Room Chat - Claude Instructions

## Voice Mode Settings
- **Auto-activate voice mode**: When user says "turn on voice mode", automatically activate voice mode
- **Always set wait_for_response=false**: Never wait for voice responses, allow text replies
- **Voice mode trigger**: Any mention of "turn on voice mode" should immediately activate voice mode

## Project Context
- iOS SwiftUI music theory chat app
- Uses OpenAI API for responses with structured JSON format
- Features audio playback of musical examples (chords, scales, progressions)
- RAG (Retrieval Augmented Generation) system for consistent high-quality responses

## Current Focus
- Implementing proper RAG system where AI uses curated reference examples as context
- NOT copy-paste responses, but AI-generated responses guided by perfect examples
- Building music theory knowledge base starting with major chords