import AVFoundation
import Foundation

class SoundEngine: ObservableObject {
    static let shared = SoundEngine()
    
    private var audioEngine: AVAudioEngine
    private var sampler: AVAudioUnitSampler
    private var reverb: AVAudioUnitReverb
    private var delay: AVAudioUnitDelay
    
    private init() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        reverb = AVAudioUnitReverb()
        delay = AVAudioUnitDelay()
        
        setupAudioEngine()
        loadSoundFont()
    }
    
    // Simple methods for slide view
    func playNote(midiNote: Int, duration: Double) {
        sampler.startNote(UInt8(midiNote), withVelocity: 80, onChannel: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.sampler.stopNote(UInt8(midiNote), onChannel: 0)
        }
    }
    
    func playChord(midiNotes: [Int], duration: Double) {
        for note in midiNotes {
            sampler.startNote(UInt8(note), withVelocity: 80, onChannel: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            for note in midiNotes {
                self?.sampler.stopNote(UInt8(note), onChannel: 0)
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
    
    private func loadSoundFont() {
        Logger.shared.audio("Attempting to load SoundFont")
        
        guard let soundFontURL = Bundle.main.url(forResource: "Yamaha_C7__Normalized_", withExtension: "sf2") else {
            Logger.shared.audio("No SoundFont found, falling back to default instrument")
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
    
    func playNote(_ note: Note, duration: TimeInterval = 0.5, velocity: UInt8 = 80) {
        Logger.shared.audio("Playing note: \(note.name) (MIDI: \(note.midi)) for \(duration)s")
        sampler.startNote(UInt8(note.midi), withVelocity: velocity, onChannel: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.sampler.stopNote(UInt8(note.midi), onChannel: 0)
        }
    }
    
    func playChord(_ chord: Chord, duration: TimeInterval = 1.0, velocity: UInt8 = 70) {
        Logger.shared.audio("Playing chord: \(chord.symbol) (\(chord.notes.count) notes)")
        for note in chord.notes {
            sampler.startNote(UInt8(note.midi), withVelocity: velocity, onChannel: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            for note in chord.notes {
                self?.sampler.stopNote(UInt8(note.midi), onChannel: 0)
            }
        }
    }
    
    func playScale(_ scale: Scale, tempo: Double = 120) {
        let noteDuration = 60.0 / tempo
        Logger.shared.audio("Playing scale: \(scale.root.name) \(scale.type) (\(scale.notes.count) notes, tempo: \(tempo))")
        
        for (index, note) in scale.notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * noteDuration) { [weak self] in
                self?.playNote(note, duration: noteDuration * 0.9)
            }
        }
    }
    
    func playChordProgression(_ chords: [Chord], tempo: Double = 80) {
        let chordDuration = (60.0 / tempo) * 2
        let chordNames = chords.map { $0.symbol }.joined(separator: " → ")
        Logger.shared.audio("Playing chord progression: \(chordNames) (tempo: \(tempo))")
        
        for (index, chord) in chords.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * chordDuration) { [weak self] in
                self?.playChord(chord, duration: chordDuration * 0.9)
            }
        }
    }
    
    func playInterval(_ note1: Note, _ note2: Note, simultaneous: Bool = false) {
        if simultaneous {
            sampler.startNote(UInt8(note1.midi), withVelocity: 80, onChannel: 0)
            sampler.startNote(UInt8(note2.midi), withVelocity: 80, onChannel: 0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.sampler.stopNote(UInt8(note1.midi), onChannel: 0)
                self?.sampler.stopNote(UInt8(note2.midi), onChannel: 0)
            }
        } else {
            playNote(note1, duration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.playNote(note2, duration: 0.5)
            }
        }
    }
    
    func playArpeggio(_ chord: Chord, pattern: [Int] = [0, 1, 2, 1], tempo: Double = 120) {
        let noteDuration = 60.0 / tempo / 2
        
        for (step, noteIndex) in pattern.enumerated() {
            if noteIndex < chord.notes.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * noteDuration) { [weak self] in
                    self?.playNote(chord.notes[noteIndex], duration: noteDuration * 0.9, velocity: 70)
                }
            }
        }
    }
    
    func stopAllNotes() {
        for midi in 0...127 {
            sampler.stopNote(UInt8(midi), onChannel: 0)
        }
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
    
    /// Play a sequence of timed note events - handles everything from single notes to full songs
    func playTimedSequence(_ events: [NoteEvent], tempo: Double = defaultTempo) {
        Logger.shared.audio("Playing timed sequence with \(events.count) events at \(tempo) BPM")
        
        for event in events {
            let startTime = ticksToSeconds(event.startTick, tempo: tempo)
            let duration = ticksToSeconds(event.durationTicks, tempo: tempo)
            
            // Schedule note to start
            DispatchQueue.main.asyncAfter(deadline: .now() + startTime) { [weak self] in
                self?.sampler.startNote(UInt8(event.note), withVelocity: event.velocity, onChannel: 0)
                
                // Schedule note to stop
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    self?.sampler.stopNote(UInt8(event.note), onChannel: 0)
                }
            }
        }
    }
    
    /// Convenience method to play a simple chord
    func playChordAsSequence(midiNotes: [Int], durationTicks: Int = 480) {
        let events = midiNotes.map { note in
            NoteEvent(note: note, startTick: 0, durationTicks: durationTicks)
        }
        playTimedSequence(events)
    }
}