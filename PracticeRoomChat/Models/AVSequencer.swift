import AVFoundation
import Foundation

@available(iOS 13.0, *)
class AVSequencer {
    private let engine: AVAudioEngine
    private let sequencer: AVAudioSequencer
    private let sampler: AVAudioUnitSampler
    private var positionTimer: Timer?
    private var currentEvents: [SoundEngine.NoteEvent] = []
    private var currentTempo: Double = 120.0

    init(engine: AVAudioEngine, sampler: AVAudioUnitSampler) {
        self.engine = engine
        self.sampler = sampler

        // Create sequencer attached to the engine
        self.sequencer = AVAudioSequencer(audioEngine: engine)
    }
    
    func playEvents(_ events: [SoundEngine.NoteEvent], tempo: Double) {
        // Stop any existing playback
        stop()

        // Store events and tempo for position tracking
        currentEvents = events
        currentTempo = tempo

        // Create a temporary MIDI file from the events
        if let midiFileURL = createMIDIFile(from: events, tempo: tempo) {
            do {
                // Load the MIDI file into the sequencer
                try sequencer.load(from: midiFileURL, options: [])

                // Route all tracks to our sampler
                for track in sequencer.tracks {
                    track.destinationAudioUnit = sampler
                }

                // Set playback rate based on tempo
                // Default MIDI tempo is 120 BPM, so adjust rate accordingly
                sequencer.rate = Float(tempo / 120.0)

                // Prepare and start playback
                sequencer.currentPositionInBeats = 0
                sequencer.prepareToPlay()

                try sequencer.start()
                Logger.shared.audio("AVSequencer started with \(events.count) events at \(tempo) BPM")

                // Start position tracking for keyboard visualization
                startPositionTracking()

                // Clean up temp file after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    try? FileManager.default.removeItem(at: midiFileURL)
                }
            } catch {
                Logger.shared.error("Failed to load/start sequencer: \(error)")
            }
        }
    }
    
    private func createMIDIFile(from events: [SoundEngine.NoteEvent], tempo: Double) -> URL? {
        // Create a simple Type 0 MIDI file
        var midiData = Data()
        
        // MIDI Header
        midiData.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // "MThd"
        midiData.append(contentsOf: [0x00, 0x00, 0x00, 0x06]) // Header length
        midiData.append(contentsOf: [0x00, 0x00]) // Format 0
        midiData.append(contentsOf: [0x00, 0x01]) // 1 track
        midiData.append(contentsOf: [0x01, 0xE0]) // 480 ticks per beat
        
        // Track header
        midiData.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // "MTrk"
        let trackLengthPosition = midiData.count
        midiData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Track length (will update later)
        
        var trackData = Data()
        
        // Add tempo event at the beginning
        let microsecondsPerBeat = UInt32(60_000_000 / tempo)
        trackData.append(contentsOf: [0x00, 0xFF, 0x51, 0x03]) // Delta time 0, Tempo meta event
        trackData.append(UInt8((microsecondsPerBeat >> 16) & 0xFF))
        trackData.append(UInt8((microsecondsPerBeat >> 8) & 0xFF))
        trackData.append(UInt8(microsecondsPerBeat & 0xFF))
        
        // Sort events by start time
        let sortedEvents = events.sorted { $0.startTick < $1.startTick }
        
        // Track all note off events we need to insert
        var noteOffEvents: [(tick: Int, note: UInt8)] = []
        var lastTick = 0
        
        for event in sortedEvents {
            // Calculate when this note ends
            let endTick = event.startTick + event.durationTicks
            noteOffEvents.append((tick: endTick, note: UInt8(event.note)))
            
            // Process any note-offs that should happen before this note-on
            noteOffEvents.sort { $0.tick < $1.tick }
            while !noteOffEvents.isEmpty && noteOffEvents[0].tick <= event.startTick {
                let noteOff = noteOffEvents.removeFirst()
                let deltaTime = noteOff.tick - lastTick
                trackData.append(contentsOf: encodeVariableLength(deltaTime))
                trackData.append(contentsOf: [0x80, noteOff.note, 0x40]) // Note off
                lastTick = noteOff.tick
            }
            
            // Add note on event
            let deltaTime = event.startTick - lastTick
            trackData.append(contentsOf: encodeVariableLength(deltaTime))
            trackData.append(contentsOf: [0x90, UInt8(event.note), event.velocity]) // Note on
            lastTick = event.startTick
        }
        
        // Add remaining note off events
        noteOffEvents.sort { $0.tick < $1.tick }
        for noteOff in noteOffEvents {
            let deltaTime = noteOff.tick - lastTick
            trackData.append(contentsOf: encodeVariableLength(deltaTime))
            trackData.append(contentsOf: [0x80, noteOff.note, 0x40]) // Note off
            lastTick = noteOff.tick
        }
        
        // End of track
        trackData.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00])
        
        // Update track length
        let trackLength = UInt32(trackData.count)
        midiData[trackLengthPosition] = UInt8((trackLength >> 24) & 0xFF)
        midiData[trackLengthPosition + 1] = UInt8((trackLength >> 16) & 0xFF)
        midiData[trackLengthPosition + 2] = UInt8((trackLength >> 8) & 0xFF)
        midiData[trackLengthPosition + 3] = UInt8(trackLength & 0xFF)
        
        // Append track data
        midiData.append(trackData)
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_\(UUID().uuidString).mid")
        do {
            try midiData.write(to: tempURL)
            Logger.shared.audio("Created temporary MIDI file with \(events.count) events")
            return tempURL
        } catch {
            Logger.shared.error("Failed to write MIDI file: \(error)")
            return nil
        }
    }
    
    private func encodeVariableLength(_ value: Int) -> [UInt8] {
        var result: [UInt8] = []
        var val = value
        
        if val == 0 {
            return [0]
        }
        
        while val > 0 {
            var byte = UInt8(val & 0x7F)
            val >>= 7
            if !result.isEmpty {
                byte |= 0x80
            }
            result.insert(byte, at: 0)
        }
        
        return result
    }
    
    func stop() {
        sequencer.stop()
        sequencer.currentPositionInBeats = 0

        // Stop position tracking
        stopPositionTracking()

        // Stop all notes on sampler
        for midi in 0...127 {
            sampler.stopNote(UInt8(midi), onChannel: 0)
        }

        // Clear playing notes
        SoundEngine.shared.currentlyPlayingNotes.removeAll()
    }

    private func startPositionTracking() {
        stopPositionTracking()

        // Update keyboard 30 times per second for smooth visualization
        positionTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            self?.updateCurrentlyPlayingNotes()
        }
    }

    private func stopPositionTracking() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    private func updateCurrentlyPlayingNotes() {
        guard sequencer.isPlaying else {
            stopPositionTracking()
            SoundEngine.shared.currentlyPlayingNotes.removeAll()
            return
        }

        // Get current position in ticks
        let currentBeats = sequencer.currentPositionInBeats
        let ticksPerBeat = Double(SoundEngine.defaultTicksPerBeat)
        let currentTick = Int(currentBeats * ticksPerBeat)

        // Find which notes should be playing at this position
        var activeNotes = Set<Int>()
        for event in currentEvents {
            let noteStart = event.startTick
            let noteEnd = event.startTick + event.durationTicks

            if currentTick >= noteStart && currentTick < noteEnd {
                activeNotes.insert(event.note)
            }
        }

        // Update the shared SoundEngine's playing notes on main thread
        DispatchQueue.main.async {
            SoundEngine.shared.currentlyPlayingNotes = activeNotes
        }
    }
    
    var isPlaying: Bool {
        return sequencer.isPlaying
    }
}