import AVFoundation

// Test if AVAudioSequencer is available on iOS
@available(iOS 13.0, *)
class ModernSequencer {
    private let engine = AVAudioEngine()
    private let sequencer: AVAudioSequencer
    private let sampler = AVAudioUnitSampler()
    
    init() {
        // AVAudioSequencer connects directly to the audio engine!
        sequencer = AVAudioSequencer(audioEngine: engine)
        
        // Attach sampler to engine
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        // Load soundfont
        if let url = Bundle.main.url(forResource: "Yamaha_C7__Normalized_", withExtension: "sf2") {
            try? sampler.loadSoundBankInstrument(at: url, program: 0, bankMSB: 0x79, bankLSB: 0)
        }
        
        // Start engine
        try? engine.start()
    }
    
    func playMIDIFile(url: URL) {
        // AVAudioSequencer can load MIDI files directly!
        try? sequencer.load(from: url, options: [])
        sequencer.prepareToPlay()
        try? sequencer.start()
    }
    
    func createAndPlayEvents(events: [(note: Int, start: Double, duration: Double)], tempo: Double) {
        // Create a new track
        let track = sequencer.createTrack()!
        
        // AVAudioSequencer uses beats, not ticks
        // Add events to track
        for event in events {
            // This would need AVMusicEvent API which might not be fully exposed
            // But the concept is: sequencer handles all timing internally
        }
        
        sequencer.currentPositionInBeats = 0
        sequencer.rate = Float(tempo / 120.0) // Relative to 120 BPM
        sequencer.prepareToPlay()
        try? sequencer.start()
    }
}

print("AVAudioSequencer test - this is the proper way to do MIDI on iOS")