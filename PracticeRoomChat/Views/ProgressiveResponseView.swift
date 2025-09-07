import SwiftUI
import AVFoundation

// MARK: - Data Models
struct ResponseSegment: Identifiable {
    let id = UUID()
    let text: String
    let audio: AudioInfo?
    let readingPause: TimeInterval // Time to wait after text appears before audio
    
    struct AudioInfo {
        let midiNotes: [Int]
        let duration: TimeInterval
        let label: String // Clickable text label
    }
}

struct ProgressiveResponse {
    let segments: [ResponseSegment]
    
    // Parse response format with inline clickable audio
    static func parse(_ content: String) -> ProgressiveResponse {
        var segments: [ResponseSegment] = []
        let lines = content.components(separatedBy: "\n")
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            
            // Parse line for inline audio markers
            var currentText = ""
            var lastIndex = line.startIndex
            
            // Find all [AUDIO:...] markers in the line
            let pattern = "\\[AUDIO:([^\\]]+)\\]"
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line))
            
            for match in matches {
                guard let range = Range(match.range, in: line) else { continue }
                
                // Add text before the audio marker
                let textBefore = String(line[lastIndex..<range.lowerBound])
                if !textBefore.isEmpty {
                    currentText += textBefore
                }
                
                // Parse audio content: [AUDIO:60,64,67:2.0:major third]
                let audioContent = String(line[range])
                let audioData = audioContent
                    .replacingOccurrences(of: "[AUDIO:", with: "")
                    .replacingOccurrences(of: "]", with: "")
                let parts = audioData.split(separator: ":")
                
                if parts.count >= 3 {
                    let notes = parts[0].split(separator: ",").compactMap { Int($0) }
                    let duration = Double(parts[1]) ?? 1.0
                    let label = String(parts[2])
                    
                    // Add the clickable text to the current text
                    currentText += label
                    
                    // Create segment with embedded audio
                    if !currentText.isEmpty {
                        segments.append(ResponseSegment(
                            text: currentText,
                            audio: ResponseSegment.AudioInfo(
                                midiNotes: notes,
                                duration: duration,
                                label: label
                            ),
                            readingPause: 0.8
                        ))
                        currentText = ""
                    }
                }
                
                lastIndex = range.upperBound
            }
            
            // Add any remaining text after the last audio marker
            if lastIndex < line.endIndex {
                let remainingText = String(line[lastIndex...])
                if !remainingText.isEmpty {
                    segments.append(ResponseSegment(
                        text: remainingText,
                        audio: nil,
                        readingPause: 0.8
                    ))
                }
            } else if matches.isEmpty {
                // No audio markers in this line
                segments.append(ResponseSegment(
                    text: line,
                    audio: nil,
                    readingPause: 1.0
                ))
            }
        }
        
        return ProgressiveResponse(segments: segments)
    }
}

// MARK: - Main Progressive Response View
struct ProgressiveResponseView: View {
    let response: ProgressiveResponse
    @Binding var highlightedNotes: Set<Int>
    var scrollProxy: ScrollViewProxy? = nil
    var messageId: UUID? = nil
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var visibleSegments: [ResponseSegment] = []
    @State private var currentSegmentIndex = 0
    @State private var isPlaying = true
    @State private var clickableAudioEnabled = false
    @State private var playingAudioId: UUID? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(visibleSegments) { segment in
                if let audio = segment.audio {
                    // Text with inline clickable part
                    InlineAudioText(
                        fullText: segment.text,
                        clickableText: audio.label,
                        audio: audio,
                        isEnabled: clickableAudioEnabled,
                        isPlaying: playingAudioId == segment.id,
                        onTap: {
                            if clickableAudioEnabled {
                                playAudio(audio, segmentId: segment.id)
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // Regular text
                    Text(segment.text)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Keyboard is now displayed in ChatView, not here
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            startProgression()
        }
    }
    
    private func startProgression() {
        guard !response.segments.isEmpty else { return }
        processNextSegment()
    }
    
    private func processNextSegment() {
        guard currentSegmentIndex < response.segments.count else {
            // Finished all segments
            isPlaying = false
            clickableAudioEnabled = true
            return
        }
        
        let segment = response.segments[currentSegmentIndex]
        
        // Show the text with smooth animation
        withAnimation(.easeInOut(duration: 0.3)) {
            visibleSegments.append(segment)
        }
        
        // Smooth scroll to keep new content visible
        if let proxy = scrollProxy {
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
        
        // Wait for reading pause
        DispatchQueue.main.asyncAfter(deadline: .now() + segment.readingPause) {
            if let audio = segment.audio {
                // Play audio and highlight notes
                playAudio(audio, segmentId: segment.id)
                
                // Wait for audio to finish then move to next segment
                DispatchQueue.main.asyncAfter(deadline: .now() + audio.duration) {
                    withAnimation {
                        highlightedNotes.removeAll()
                        playingAudioId = nil
                    }
                    currentSegmentIndex += 1
                    processNextSegment()
                }
            } else {
                // No audio, move to next segment
                currentSegmentIndex += 1
                processNextSegment()
            }
        }
    }
    
    private func playAudio(_ audio: ResponseSegment.AudioInfo, segmentId: UUID) {
        // Highlight notes on keyboard
        withAnimation {
            highlightedNotes = Set(audio.midiNotes)
            playingAudioId = segmentId
        }
        
        // Play the audio
        soundEngine.playChord(midiNotes: audio.midiNotes, duration: audio.duration)
        
        // Clear highlights after audio finishes (only if this is a manual click)
        if clickableAudioEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + audio.duration) {
                withAnimation {
                    highlightedNotes.removeAll()
                    playingAudioId = nil
                }
            }
        }
    }
}

// MARK: - Inline Audio Text with Clickable Part
struct InlineAudioText: View {
    let fullText: String
    let clickableText: String
    let audio: ResponseSegment.AudioInfo
    let isEnabled: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        // Find where the clickable text is in the full text
        if let range = fullText.range(of: clickableText) {
            let beforeText = String(fullText[..<range.lowerBound])
            let afterText = String(fullText[range.upperBound...])
            
            // Use Text concatenation for inline layout instead of HStack
            (Text(beforeText)
                .font(.system(size: 18))
                .foregroundColor(.primary)
            + Text(clickableText)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isEnabled ? .blue : .blue.opacity(0.8))
                .underline(true, color: .blue.opacity(0.4))
            + Text(afterText)
                .font(.system(size: 18))
                .foregroundColor(.primary))
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture {
                // For now, tap the whole text to trigger the clickable part
                if isEnabled {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                    onTap()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
                }
            }
        } else {
            // Fallback if we can't find the clickable text
            Text(fullText)
                .font(.system(size: 18))
                .foregroundColor(.primary)
        }
    }
}

// Removed simplified keyboard - using the existing beautiful MidiKeyboardView instead

#Preview {
    @State var highlightedNotes: Set<Int> = []
    
    return ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Progressive Response Demo")
                .font(.title2)
                .bold()
            
            ProgressiveResponseView(
                response: ProgressiveResponse.parse("""
                A major chord consists of three notes.
                The root note [AUDIO:60:1.0:C (root)]
                the major third [AUDIO:64:1.0:E (major third)]
                and the perfect fifth [AUDIO:67:1.0:G (perfect fifth)]
                Together they create [AUDIO:60,64,67:2.0:C Major Chord]
                """),
                highlightedNotes: .constant([])
            )
            
            // Show keyboard in preview
            MidiKeyboardView(
                midiNotes: Array(highlightedNotes),
                showLabels: true,
                octaves: 1
            )
            .frame(height: 100)
        }
        .padding()
    }
}