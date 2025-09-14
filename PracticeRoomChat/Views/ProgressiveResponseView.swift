import SwiftUI
import AVFoundation

// MARK: - Data Models
struct ResponseSegment: Identifiable {
    let id = UUID()
    let text: String  // Full line text including placeholders for audio
    let audioElements: [AudioElement]  // All audio elements in this line
    let readingPauseTicks: Int // Ticks to wait after text appears before audio
    let tempo: Double // BPM for this segment
    
    struct AudioElement {
        let id = UUID()
        let events: [SoundEngine.NoteEvent]  // List of timed note events (tick-based)
        let totalDurationTicks: Int          // Total duration in ticks
        let label: String                     // Clickable text label
        let placeholder: String               // Placeholder in text to replace with clickable
        let tempo: Double                     // BPM for playback
    }
}

struct ProgressiveResponse {
    let segments: [ResponseSegment]
    
    // Parse response format with unified timed events - keeping full lines intact
    static func parse(_ content: String) -> ProgressiveResponse {
        var segments: [ResponseSegment] = []
        let lines = content.components(separatedBy: "\n")
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            
            var audioElements: [ResponseSegment.AudioElement] = []
            var processedLine = line
            var placeholderIndex = 0
            
            // Find all MIDI sequences in the line
            let midiPattern = "\\[MIDI:([^\\]]+)\\]"
            if let regex = try? NSRegularExpression(pattern: midiPattern) {
                let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
                
                // Process matches in reverse to maintain string indices
                for match in matches.reversed() {
                    if let range = Range(match.range, in: line) {
                        let midiContent = String(line[range])
                            .replacingOccurrences(of: "[MIDI:", with: "")
                            .replacingOccurrences(of: "]", with: "")
                        
                        let parts = midiContent.split(separator: ":")
                        if parts.count >= 2 {
                            let eventStrings = parts[0].split(separator: ",")
                            let label = String(parts[1])
                            let tempo = parts.count >= 3 ? Double(parts[2]) ?? 120.0 : 120.0
                            
                            var events: [SoundEngine.NoteEvent] = []
                            var maxEndTime: Double = 0
                            
                            for eventStr in eventStrings {
                                let eventParts = eventStr.split(separator: "@")
                                if eventParts.count == 2,
                                   let note = Int(eventParts[0]) {
                                    let timingStr = String(eventParts[1])
                                    let timingParts = timingStr.split(separator: "-")
                                    if timingParts.count == 2 {
                                        // Check if it's tick format (ends with 't') or seconds format
                                        let startStr = String(timingParts[0])
                                        let durationStr = String(timingParts[1])
                                        
                                        if startStr.hasSuffix("t") && durationStr.hasSuffix("t") {
                                            // Tick format
                                            let startTick = Int(startStr.dropLast()) ?? 0
                                            let durationTicks = Int(durationStr.dropLast()) ?? 480
                                            events.append(SoundEngine.NoteEvent(
                                                note: note,
                                                startTick: startTick,
                                                durationTicks: durationTicks
                                            ))
                                            maxEndTime = max(maxEndTime, Double(startTick + durationTicks))
                                        } else {
                                            // Legacy seconds format - convert to ticks (assume 120 BPM)
                                            let startTime = Double(startStr) ?? 0
                                            let duration = Double(durationStr) ?? 1.0
                                            let startTick = Int(startTime * 480 / 0.5) // 480 ticks per beat at 120 BPM
                                            let durationTicks = Int(duration * 480 / 0.5)
                                            events.append(SoundEngine.NoteEvent(
                                                note: note,
                                                startTick: startTick,
                                                durationTicks: durationTicks
                                            ))
                                            maxEndTime = max(maxEndTime, Double(startTick + durationTicks))
                                        }
                                    }
                                }
                            }
                            
                            if !events.isEmpty {
                                let placeholder = "{{AUDIO_\(placeholderIndex)}}"
                                audioElements.append(ResponseSegment.AudioElement(
                                    events: events,
                                    totalDurationTicks: Int(maxEndTime),
                                    label: label,
                                    placeholder: placeholder,
                                    tempo: tempo
                                ))
                                processedLine.replaceSubrange(range, with: placeholder)
                                placeholderIndex += 1
                            }
                        }
                    }
                }
            }
            
            
            // Add the complete line as a single segment
            // Use tempo from first audio element if available, otherwise default
            let segmentTempo = audioElements.first?.tempo ?? 120.0
            
            // Calculate reading time based on word count for ALL segments
            // Target: 400 words per minute (faster than average 200-250 wpm)
            // Count words in the text (excluding placeholders)
            let cleanText = processedLine.replacingOccurrences(of: #"\{\{AUDIO_\d+\}\}"#, with: "", options: .regularExpression)
            let wordCount = cleanText.split(separator: " ").count
            // 400 wpm = 6.67 words per second = 0.15 seconds per word
            // Convert to ticks: 0.15 seconds * (480 ticks/beat) / (0.5 seconds/beat at 120 BPM)
            let ticksPerWord = 144  // 0.15 seconds worth of ticks at 120 BPM
            let readingPauseTicks = max(wordCount * ticksPerWord, 240)  // Minimum 0.5 beat
            
            segments.append(ResponseSegment(
                text: processedLine,
                audioElements: audioElements,
                readingPauseTicks: readingPauseTicks,
                tempo: segmentTempo
            ))
        }
        
        return ProgressiveResponse(segments: segments)
    }
}

// MARK: - Main Progressive Response View
struct ProgressiveResponseView: View {
    let response: ProgressiveResponse
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
                // Render each line with inline audio elements
                LineWithInlineAudio(
                    text: segment.text,
                    audioElements: segment.audioElements,
                    isEnabled: clickableAudioEnabled,
                    playingElementIds: playingAudioId == segment.id ? Set(segment.audioElements.map { $0.id }) : [],
                    onAudioTap: { element in
                        if clickableAudioEnabled {
                            playAudioElement(element, segmentId: segment.id)
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
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
        
        // Always wait for full text reading time before playing audio
        // This ensures users can read the entire segment regardless of where MIDI elements appear
        let pauseSeconds = Double(segment.readingPauseTicks) / Double(SoundEngine.defaultTicksPerBeat) * (60.0 / segment.tempo)
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseSeconds) {
            if !segment.audioElements.isEmpty {
                // After full reading time, play all audio elements in sequence
                playSegmentAudio(segment)
            } else {
                // No audio, move to next segment
                currentSegmentIndex += 1
                processNextSegment()
            }
        }
    }
    
    private func playSegmentAudio(_ segment: ResponseSegment) {
        // Play audio elements in sequence during progression
        var totalDelay: TimeInterval = 0
        
        for element in segment.audioElements {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                playAudioElement(element, segmentId: segment.id, tempo: element.tempo)
            }
            // Convert ticks to seconds for delay calculation using element's tempo
            let elementDuration = Double(element.totalDurationTicks) / Double(SoundEngine.defaultTicksPerBeat) * (60.0 / element.tempo)
            totalDelay += elementDuration + 0.3 // Small gap between elements
        }
        
        // Move to next segment after all audio
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            withAnimation {
                playingAudioId = nil
            }
            currentSegmentIndex += 1
            processNextSegment()
        }
    }
    
    private func playAudioElement(_ element: ResponseSegment.AudioElement, segmentId: UUID, tempo: Double = 120.0) {
        // Notes are automatically highlighted by SoundEngine
        withAnimation {
            playingAudioId = segmentId
        }
        
        // Play the audio using the unified timed sequence with tempo
        soundEngine.playTimedSequence(element.events, tempo: tempo)
        
        // Clear highlights after audio finishes (only if this is a manual click)
        if clickableAudioEnabled {
            let durationSeconds = Double(element.totalDurationTicks) / Double(SoundEngine.defaultTicksPerBeat) * (60.0 / tempo)
            DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds) {
                withAnimation {
                    playingAudioId = nil
                }
            }
        }
    }
}

// MARK: - Line with Multiple Inline Audio Elements
struct LineWithInlineAudio: View {
    let text: String
    let audioElements: [ResponseSegment.AudioElement]
    let isEnabled: Bool
    let playingElementIds: Set<UUID>
    let onAudioTap: (ResponseSegment.AudioElement) -> Void
    
    var body: some View {
        if audioElements.isEmpty {
            // No audio elements, just plain text
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // Use HStack with proper wrapping for inline elements
            WrappingHStack(
                text: text,
                audioElements: audioElements,
                isEnabled: isEnabled,
                playingElementIds: playingElementIds,
                onAudioTap: onAudioTap
            )
        }
    }
}

// Helper view to handle wrapping text with clickable elements
struct WrappingHStack: View {
    let text: String
    let audioElements: [ResponseSegment.AudioElement]
    let isEnabled: Bool
    let playingElementIds: Set<UUID>
    let onAudioTap: (ResponseSegment.AudioElement) -> Void
    
    var body: some View {
        // Build an array of text segments and audio elements
        let segments = buildSegments()
        
        // Use a single Text view with concatenation for proper inline flow
        segments.reduce(Text("")) { result, segment in
            switch segment {
            case .text(let str):
                return result + Text(str)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            case .audio(let element):
                let isPlaying = playingElementIds.contains(element.id)
                return result + Text(element.label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isEnabled ? (isPlaying ? .blue.opacity(0.7) : .blue) : .blue.opacity(0.6))
                    .underline(true, color: .blue.opacity(0.4))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(
            // Add invisible tap targets for audio elements
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, in: geometry.size)
                    }
            }
        )
    }
    
    enum Segment {
        case text(String)
        case audio(ResponseSegment.AudioElement)
    }
    
    private func buildSegments() -> [Segment] {
        var segments: [Segment] = []
        var currentText = text
        
        // Sort audio elements by their position in the text
        let sortedElements = audioElements.sorted { elem1, elem2 in
            guard let range1 = text.range(of: elem1.placeholder),
                  let range2 = text.range(of: elem2.placeholder) else {
                return false
            }
            return range1.lowerBound < range2.lowerBound
        }
        
        for element in sortedElements {
            if let range = currentText.range(of: element.placeholder) {
                // Add text before the audio element
                let beforeText = String(currentText[..<range.lowerBound])
                if !beforeText.isEmpty {
                    segments.append(.text(beforeText))
                }
                
                // Add the audio element
                segments.append(.audio(element))
                
                // Update current text to continue from after this element
                currentText = String(currentText[range.upperBound...])
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            segments.append(.text(currentText))
        }
        
        return segments
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        // This is a simplified tap handler - in production you'd calculate
        // the actual text layout to determine which element was tapped
        // For now, we'll make the entire line tappable and play the first audio element
        if isEnabled, let firstAudio = audioElements.first {
            onAudioTap(firstAudio)
        }
    }
}

// Removed simplified keyboard - using the existing beautiful MidiKeyboardView instead

#Preview {
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
                """)
            )

            // Show keyboard in preview
            MidiKeyboardView(
                midiNotes: Array(SoundEngine.shared.currentlyPlayingNotes),
                showLabels: true,
                octaves: 1
            )
            .frame(height: 100)
        }
        .padding()
    }
}