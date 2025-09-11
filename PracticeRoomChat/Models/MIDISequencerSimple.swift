import Foundation
import AVFoundation
import CoreMIDI
import AudioToolbox

/// Simplified Logic Pro-style MIDI sequencer that uses the existing sampler
class MIDISequencerSimple {
    private var musicSequence: MusicSequence?
    private var musicPlayer: MusicPlayer?
    private let sampler: AVAudioUnitSampler
    private var scheduledNotes: [(note: UInt8, endTime: TimeInterval)] = []
    private var timer: Timer?
    
    init(engine: AVAudioEngine, sampler: AVAudioUnitSampler) {
        self.sampler = sampler
    }
    
    func playEvents(_ events: [SoundEngine.NoteEvent], tempo: Double) {
        // Stop any existing playback
        stop()
        
        // Clear scheduled notes
        scheduledNotes.removeAll()
        
        // Convert tempo to seconds per beat
        let secondsPerBeat = 60.0 / tempo
        let ticksPerBeat = Double(SoundEngine.defaultTicksPerBeat)
        
        // Sort events by start time
        let sortedEvents = events.sorted { $0.startTick < $1.startTick }
        
        // Schedule all events
        for event in sortedEvents {
            let startTime = (Double(event.startTick) / ticksPerBeat) * secondsPerBeat
            let duration = (Double(event.durationTicks) / ticksPerBeat) * secondsPerBeat
            
            // Debug logging for Bb
            if event.note == 50 {
                Logger.shared.audio("MIDI 50 (Bb): Scheduling at \(startTime)s for \(duration)s")
            }
            
            // Schedule note on
            DispatchQueue.main.asyncAfter(deadline: .now() + startTime) { [weak self] in
                self?.sampler.startNote(UInt8(event.note), withVelocity: event.velocity, onChannel: 0)
                
                if event.note == 50 {
                    Logger.shared.audio("MIDI 50 (Bb): Started playing")
                }
                
                // Schedule note off
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    self?.sampler.stopNote(UInt8(event.note), onChannel: 0)
                    
                    if event.note == 50 {
                        Logger.shared.audio("MIDI 50 (Bb): Stopped playing after \(duration)s")
                    }
                }
            }
        }
        
        Logger.shared.audio("Scheduled \(events.count) events at \(tempo) BPM")
    }
    
    func stop() {
        // Stop all notes
        for midi in 0...127 {
            sampler.stopNote(UInt8(midi), onChannel: 0)
        }
    }
}