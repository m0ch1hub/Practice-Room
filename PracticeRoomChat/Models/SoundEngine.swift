import AVFoundation
import Foundation
import CoreMIDI
import AudioToolbox

class SoundEngine: ObservableObject {
    static let shared = SoundEngine()

    @Published var currentlyPlayingNotes: Set<Int> = []
    @Published var keyboardRange: (minNote: Int, maxNote: Int) = (60, 71) // Default C4-B4
    @Published var currentSoundFont: SoundFont = .yamaha

    private var audioEngine: AVAudioEngine
    private var sampler: AVAudioUnitSampler
    private var reverb: AVAudioUnitReverb
    private var delay: AVAudioUnitDelay
    private var avSequencer: AVSequencer?

    enum SoundFont: String, CaseIterable {
        case yamaha = "Yamaha C7 Piano"
        case rhodes = "jRhodes3 Electric Piano"

        var fileName: String {
            switch self {
            case .yamaha: return "Yamaha_C7__Normalized_"
            case .rhodes: return "jRhodes3"
            }
        }
    }

    private init() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        reverb = AVAudioUnitReverb()
        delay = AVAudioUnitDelay()
        
        setupAudioEngine()
        loadSoundFont()
        // Use AVAudioSequencer for proper timing
        if #available(iOS 13.0, *) {
            avSequencer = AVSequencer(engine: audioEngine, sampler: sampler)
        }
    }
    
    // Simple methods for slide view
    func playNote(midiNote: Int, duration: Double) {
        sampler.startNote(UInt8(midiNote), withVelocity: 80, onChannel: 0)
        DispatchQueue.main.async { [weak self] in
            self?.currentlyPlayingNotes.insert(midiNote)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.sampler.stopNote(UInt8(midiNote), onChannel: 0)
            self?.currentlyPlayingNotes.remove(midiNote)
        }
    }
    
    func playChord(midiNotes: [Int], duration: Double) {
        for note in midiNotes {
            sampler.startNote(UInt8(note), withVelocity: 80, onChannel: 0)
        }
        DispatchQueue.main.async { [weak self] in
            for note in midiNotes {
                self?.currentlyPlayingNotes.insert(note)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            for note in midiNotes {
                self?.sampler.stopNote(UInt8(note), onChannel: 0)
                self?.currentlyPlayingNotes.remove(note)
            }
        }
    }
    
    private func setupAudioEngine() {
        Logger.shared.audio("Setting up audio engine")
        
        audioEngine.attach(sampler)
        audioEngine.attach(reverb)
        audioEngine.attach(delay)
        
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 20
        
        delay.delayTime = 0.1
        delay.feedback = 30
        delay.wetDryMix = 0
        
        audioEngine.connect(sampler, to: reverb, format: nil)
        audioEngine.connect(reverb, to: delay, format: nil)
        audioEngine.connect(delay, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            Logger.shared.audio("Audio engine started successfully")
        } catch {
            Logger.shared.error("Audio Engine setup failed: \(error)")
        }
    }
    
    func switchSoundFont(to soundFont: SoundFont) {
        currentSoundFont = soundFont
        loadSoundFont()

        // Save preference
        UserDefaults.standard.set(soundFont.rawValue, forKey: "selectedSoundFont")
    }

    private func loadSoundFont() {
        Logger.shared.audio("Attempting to load SoundFont: \(currentSoundFont.fileName)")

        // Load saved preference or default
        if let savedFont = UserDefaults.standard.string(forKey: "selectedSoundFont"),
           let font = SoundFont.allCases.first(where: { $0.rawValue == savedFont }) {
            currentSoundFont = font
        }

        guard let soundFontURL = Bundle.main.url(forResource: currentSoundFont.fileName, withExtension: "sf2") else {
            Logger.shared.audio("No SoundFont found for \(currentSoundFont.fileName), falling back to default instrument")
            loadDefaultInstrument()
            return
        }
        
        do {
            try sampler.loadSoundBankInstrument(
                at: soundFontURL,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            Logger.shared.audio("SoundFont loaded successfully")
        } catch {
            Logger.shared.audio("SoundFont loading failed, using default: \(error)")
            loadDefaultInstrument()
        }
    }
    
    private func loadDefaultInstrument() {
        guard let presetURL = Bundle.main.url(forResource: "Default", withExtension: "aupreset") else {
            Logger.shared.audio("No Default.aupreset found, sampler will use built-in instrument")
            return
        }
        
        do {
            try sampler.loadInstrument(at: presetURL)
            Logger.shared.audio("Default instrument loaded successfully")
        } catch {
            Logger.shared.error("Default instrument failed: \(error)")
        }
    }
    
    func stopAllNotes() {
        // Stop sequencer if playing
        if #available(iOS 13.0, *) {
            avSequencer?.stop()
        }

        // Stop all individual notes
        for midi in 0...127 {
            sampler.stopNote(UInt8(midi), onChannel: 0)
        }

        // Clear the playing notes set
        currentlyPlayingNotes.removeAll()
    }
    
    // MARK: - Unified Timed Event System (Tick-based)
    struct NoteEvent {
        let note: Int          // MIDI note number
        let startTick: Int     // When to start (in ticks from beginning)
        let durationTicks: Int // How long to play (in ticks)
        let velocity: UInt8    // Volume/intensity (0-127)
        
        init(note: Int, startTick: Int, durationTicks: Int, velocity: UInt8 = 80) {
            self.note = note
            self.startTick = startTick
            self.durationTicks = durationTicks
            self.velocity = velocity
        }
    }
    
    // Standard MIDI timing constants
    static let defaultTicksPerBeat = 480
    static let defaultTempo = 120.0 // BPM
    
    /// Convert ticks to seconds based on tempo
    private func ticksToSeconds(_ ticks: Int, tempo: Double = defaultTempo) -> Double {
        let ticksPerBeat = Double(Self.defaultTicksPerBeat)
        let secondsPerBeat = 60.0 / tempo
        return (Double(ticks) / ticksPerBeat) * secondsPerBeat
    }
    
    /// Play a sequence of timed note events using AVAudioSequencer for accurate timing
    func playTimedSequence(_ events: [NoteEvent], tempo: Double = defaultTempo) {
        Logger.shared.audio("Playing timed sequence with \(events.count) events at \(tempo) BPM")

        // Use AVAudioSequencer for accurate playback
        if #available(iOS 13.0, *) {
            avSequencer?.playEvents(events, tempo: tempo)
        } else {
            Logger.shared.error("AVAudioSequencer requires iOS 13.0 or later")
        }
    }
    
    /// Create MIDI file data from note events
    private func createMIDIData(from events: [NoteEvent], tempo: Double) -> Data {
        // This is a simplified MIDI file creator
        // In production, you'd want to use a proper MIDI library
        var midiData = Data()
        
        // MIDI Header
        midiData.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // "MThd"
        midiData.append(contentsOf: [0x00, 0x00, 0x00, 0x06]) // Header length
        midiData.append(contentsOf: [0x00, 0x00]) // Format 0
        midiData.append(contentsOf: [0x00, 0x01]) // 1 track
        midiData.append(contentsOf: [0x01, 0xE0]) // 480 ticks per quarter note
        
        // Track header
        midiData.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // "MTrk"
        
        // We'll fill in track length later
        let trackLengthPosition = midiData.count
        midiData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        var trackData = Data()
        
        // Tempo event
        let microsecondsPerBeat = Int(60_000_000 / tempo)
        trackData.append(0x00) // Delta time
        trackData.append(0xFF) // Meta event
        trackData.append(0x51) // Set tempo
        trackData.append(0x03) // Length
        trackData.append(UInt8((microsecondsPerBeat >> 16) & 0xFF))
        trackData.append(UInt8((microsecondsPerBeat >> 8) & 0xFF))
        trackData.append(UInt8(microsecondsPerBeat & 0xFF))
        
        // Sort events by start time
        let sortedEvents = events.sorted { $0.startTick < $1.startTick }
        
        var currentTick = 0
        var activeNotes: [(note: Int, endTick: Int)] = []
        
        for event in sortedEvents {
            // Check for note offs that should happen before this note on
            while let firstEndingNote = activeNotes.first(where: { $0.endTick <= event.startTick }) {
                let deltaTime = firstEndingNote.endTick - currentTick
                trackData.append(contentsOf: encodeVariableLength(deltaTime))
                trackData.append(0x80) // Note off
                trackData.append(UInt8(firstEndingNote.note))
                trackData.append(0x40) // Velocity
                currentTick = firstEndingNote.endTick
                activeNotes.removeAll { $0.note == firstEndingNote.note }
            }
            
            // Note on
            let deltaTime = event.startTick - currentTick
            trackData.append(contentsOf: encodeVariableLength(deltaTime))
            trackData.append(0x90) // Note on
            trackData.append(UInt8(event.note))
            trackData.append(event.velocity)
            currentTick = event.startTick
            
            activeNotes.append((note: event.note, endTick: event.startTick + event.durationTicks))
        }
        
        // Remaining note offs
        for (note, endTick) in activeNotes.sorted(by: { $0.endTick < $1.endTick }) {
            let deltaTime = endTick - currentTick
            trackData.append(contentsOf: encodeVariableLength(deltaTime))
            trackData.append(0x80) // Note off
            trackData.append(UInt8(note))
            trackData.append(0x40) // Velocity
            currentTick = endTick
        }
        
        // End of track
        trackData.append(0x00) // Delta time
        trackData.append(0xFF) // Meta event
        trackData.append(0x2F) // End of track
        trackData.append(0x00) // Length
        
        // Update track length
        let trackLength = trackData.count
        midiData[trackLengthPosition] = UInt8((trackLength >> 24) & 0xFF)
        midiData[trackLengthPosition + 1] = UInt8((trackLength >> 16) & 0xFF)
        midiData[trackLengthPosition + 2] = UInt8((trackLength >> 8) & 0xFF)
        midiData[trackLengthPosition + 3] = UInt8(trackLength & 0xFF)
        
        midiData.append(trackData)
        
        return midiData
    }
    
    /// Encode integer as MIDI variable length value
    private func encodeVariableLength(_ value: Int) -> [UInt8] {
        var bytes: [UInt8] = []
        var val = value
        
        repeat {
            var byte = UInt8(val & 0x7F)
            val >>= 7
            if !bytes.isEmpty {
                byte |= 0x80
            }
            bytes.insert(byte, at: 0)
        } while val > 0
        
        if bytes.isEmpty {
            bytes = [0]
        }
        
        return bytes
    }
    /// Convenience method to play a simple chord
    func playChordAsSequence(midiNotes: [Int], durationTicks: Int = 480) {
        let events = midiNotes.map { note in
            NoteEvent(note: note, startTick: 0, durationTicks: durationTicks)
        }
        playTimedSequence(events)
    }
}