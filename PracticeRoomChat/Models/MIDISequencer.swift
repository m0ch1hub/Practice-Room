import Foundation
import AVFoundation
import CoreMIDI
import AudioToolbox

/// Logic Pro-style MIDI sequencer using MusicSequence and MusicPlayer
class MIDISequencer {
    private var musicSequence: MusicSequence?
    private var musicPlayer: MusicPlayer?
    private var auGraph: AUGraph?
    private let engine: AVAudioEngine
    private let sampler: AVAudioUnitSampler
    
    init(engine: AVAudioEngine, sampler: AVAudioUnitSampler) {
        self.engine = engine
        self.sampler = sampler
    }
    
    func playEvents(_ events: [SoundEngine.NoteEvent], tempo: Double) {
        // Stop any existing playback
        stop()
        
        // Create new MusicSequence (like Logic's project)
        var sequence: MusicSequence?
        let status = NewMusicSequence(&sequence)
        guard status == noErr, let musicSequence = sequence else {
            Logger.shared.error("Failed to create MusicSequence")
            return
        }
        self.musicSequence = musicSequence
        
        // Create a track (like Logic's MIDI track)
        var track: MusicTrack?
        MusicSequenceNewTrack(musicSequence, &track)
        guard let musicTrack = track else {
            Logger.shared.error("Failed to create MusicTrack")
            return
        }
        
        // Set tempo on the tempo track
        var tempoTrack: MusicTrack?
        MusicSequenceGetTempoTrack(musicSequence, &tempoTrack)
        if let tempoTrack = tempoTrack {
            MusicTrackClear(tempoTrack, 0, 1000)
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, tempo)
        }
        
        // Add note events directly (like Logic's MIDI events)
        // Convert ticks to beats (480 ticks = 1 beat)
        let ticksPerBeat = Double(SoundEngine.defaultTicksPerBeat)
        
        for event in events {
            let timestamp = MusicTimeStamp(Double(event.startTick) / ticksPerBeat)
            let duration = Float32(Double(event.durationTicks) / ticksPerBeat)
            
            // Debug log for MIDI 50
            if event.note == 50 {
                Logger.shared.audio("MIDI 50 (Bb): start=\(event.startTick) ticks (\(timestamp) beats), duration=\(event.durationTicks) ticks (\(duration) beats)")
            }
            
            // Create MIDI note message
            var noteMessage = MIDINoteMessage(
                channel: 0,
                note: UInt8(event.note),
                velocity: event.velocity,
                releaseVelocity: 0,
                duration: duration
            )
            
            // Add to track
            MusicTrackNewMIDINoteEvent(musicTrack, timestamp, &noteMessage)
        }
        
        // Create player and associate with sequence
        var player: MusicPlayer?
        NewMusicPlayer(&player)
        guard let musicPlayer = player else {
            Logger.shared.error("Failed to create MusicPlayer")
            return
        }
        self.musicPlayer = musicPlayer
        
        MusicPlayerSetSequence(musicPlayer, musicSequence)
        
        // Create an AUGraph to route MIDI to our sampler
        var graph: AUGraph?
        NewAUGraph(&graph)
        
        if let graph = graph {
            self.auGraph = graph
            // Add sampler node to graph
            var samplerNode = AUNode()
            var cd = AudioComponentDescription(
                componentType: kAudioUnitType_MusicDevice,
                componentSubType: kAudioUnitSubType_Sampler,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
            AUGraphAddNode(graph, &cd, &samplerNode)
            
            // Add output node (RemoteIO for iOS)
            var outputNode = AUNode()
            var outputDesc = AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_RemoteIO,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
            AUGraphAddNode(graph, &outputDesc, &outputNode)
            
            // Connect sampler to output
            AUGraphConnectNodeInput(graph, samplerNode, 0, outputNode, 0)
            
            // Open and initialize the graph
            AUGraphOpen(graph)
            AUGraphInitialize(graph)
            
            // Get the sampler unit from the graph
            var samplerUnit: AudioUnit?
            AUGraphNodeInfo(graph, samplerNode, nil, &samplerUnit)
            
            // Load the soundfont into this sampler unit if we have one
            if let samplerUnit = samplerUnit,
               let soundFontURL = Bundle.main.url(forResource: "Yamaha_C7__Normalized_", withExtension: "sf2") {
                var preset = AUSamplerInstrumentData(
                    fileURL: Unmanaged.passUnretained(soundFontURL as CFURL),
                    instrumentType: UInt8(kInstrumentType_SF2Preset),
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                    presetID: 0
                )
                
                let status = AudioUnitSetProperty(
                    samplerUnit,
                    kAUSamplerProperty_LoadInstrument,
                    kAudioUnitScope_Global,
                    0,
                    &preset,
                    UInt32(MemoryLayout<AUSamplerInstrumentData>.size)
                )
                
                if status != noErr {
                    Logger.shared.error("Failed to load soundfont: \(status)")
                }
            }
            
            // Associate the graph with the sequence
            MusicSequenceSetAUGraph(musicSequence, graph)
            
            // Start the graph
            AUGraphStart(graph)
        }
        
        // Preroll and start playback
        MusicPlayerPreroll(musicPlayer)
        MusicPlayerStart(musicPlayer)
        
        Logger.shared.audio("Started MusicSequence playback with \(events.count) events at \(tempo) BPM")
    }
    
    func stop() {
        if let player = musicPlayer {
            MusicPlayerStop(player)
            DisposeMusicPlayer(player)
            musicPlayer = nil
        }
        
        if let graph = auGraph {
            AUGraphStop(graph)
            AUGraphUninitialize(graph)
            AUGraphClose(graph)
            DisposeAUGraph(graph)
            auGraph = nil
        }
        
        if let sequence = musicSequence {
            DisposeMusicSequence(sequence)
            musicSequence = nil
        }
    }
}