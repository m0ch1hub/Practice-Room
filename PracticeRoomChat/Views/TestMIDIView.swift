import SwiftUI

struct TestMIDIView: View {
    @StateObject private var soundEngine = SoundEngine.shared
    @State private var statusMessage = "Ready to test"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MIDI Sequencer Test")
                .font(.title)
                .bold()
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.gray)
            
            Button("Test Autumn Leaves 2-5-1") {
                testAutumnLeaves()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Test Simple C Major Chord") {
                testSimpleChord()
            }
            .buttonStyle(.bordered)
            
            Button("Test Bb Note Alone (MIDI 50)") {
                testBbAlone()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)
            
            Button("Stop All") {
                soundEngine.stopAllNotes()
                statusMessage = "Stopped"
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
    }
    
    private func testAutumnLeaves() {
        statusMessage = "Playing Autumn Leaves 2-5-1 at 100 BPM (exact MIDI file)..."
        
        // Corrected timing with proper sub-tick parsing
        let events = [
            SoundEngine.NoteEvent(note: 48, startTick: 0, durationTicks: 238),
            SoundEngine.NoteEvent(note: 51, startTick: 240, durationTicks: 118),
            SoundEngine.NoteEvent(note: 55, startTick: 360, durationTicks: 118),
            SoundEngine.NoteEvent(note: 58, startTick: 480, durationTicks: 1366),
            SoundEngine.NoteEvent(note: 63, startTick: 600, durationTicks: 118),
            SoundEngine.NoteEvent(note: 67, startTick: 720, durationTicks: 118),
            SoundEngine.NoteEvent(note: 70, startTick: 840, durationTicks: 118),
            SoundEngine.NoteEvent(note: 75, startTick: 960, durationTicks: 911),
            SoundEngine.NoteEvent(note: 58, startTick: 1920, durationTicks: 958),
            SoundEngine.NoteEvent(note: 79, startTick: 2400, durationTicks: 238),
            SoundEngine.NoteEvent(note: 80, startTick: 2640, durationTicks: 238),
            SoundEngine.NoteEvent(note: 48, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 51, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 53, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 57, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 74, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 78, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 81, startTick: 2880, durationTicks: 455),
            SoundEngine.NoteEvent(note: 57, startTick: 3360, durationTicks: 455),
            SoundEngine.NoteEvent(note: 74, startTick: 3480, durationTicks: 118),
            SoundEngine.NoteEvent(note: 84, startTick: 3480, durationTicks: 118),
            SoundEngine.NoteEvent(note: 74, startTick: 3600, durationTicks: 238),
            SoundEngine.NoteEvent(note: 82, startTick: 3600, durationTicks: 238),
            // BbMaj7 - D2 (MIDI 50) now has correct 1822 ticks
            SoundEngine.NoteEvent(note: 46, startTick: 3840, durationTicks: 1822),
            SoundEngine.NoteEvent(note: 50, startTick: 3840, durationTicks: 1822),
            SoundEngine.NoteEvent(note: 53, startTick: 3840, durationTicks: 1822),
            SoundEngine.NoteEvent(note: 57, startTick: 3840, durationTicks: 1822),
            SoundEngine.NoteEvent(note: 74, startTick: 3840, durationTicks: 478),
            SoundEngine.NoteEvent(note: 77, startTick: 3840, durationTicks: 240),
            SoundEngine.NoteEvent(note: 81, startTick: 3840, durationTicks: 238),
            SoundEngine.NoteEvent(note: 77, startTick: 4080, durationTicks: 238),
            SoundEngine.NoteEvent(note: 74, startTick: 4320, durationTicks: 238),
            SoundEngine.NoteEvent(note: 70, startTick: 4560, durationTicks: 238),
            SoundEngine.NoteEvent(note: 69, startTick: 4800, durationTicks: 238),
            SoundEngine.NoteEvent(note: 70, startTick: 5040, durationTicks: 238),
            SoundEngine.NoteEvent(note: 69, startTick: 5280, durationTicks: 238),
            SoundEngine.NoteEvent(note: 67, startTick: 5520, durationTicks: 226)
        ]
        
        soundEngine.playTimedSequence(events, tempo: 100)
    }
    
    private func testSimpleChord() {
        statusMessage = "Playing C Major chord..."
        
        // Simple C major chord - all notes at tick 0
        let events = [
            SoundEngine.NoteEvent(note: 60, startTick: 0, durationTicks: 960),
            SoundEngine.NoteEvent(note: 64, startTick: 0, durationTicks: 960),
            SoundEngine.NoteEvent(note: 67, startTick: 0, durationTicks: 960)
        ]
        
        soundEngine.playTimedSequence(events, tempo: 120)
    }
    
    private func testBbAlone() {
        statusMessage = "Playing Bb (MIDI 50) for 1890 ticks (~3.94 beats)..."
        
        // Just the Bb note that's having issues
        let events = [
            SoundEngine.NoteEvent(note: 50, startTick: 0, durationTicks: 1890)
        ]
        
        soundEngine.playTimedSequence(events, tempo: 100)
    }
}

#Preview {
    TestMIDIView()
}