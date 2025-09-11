#!/usr/bin/env python3
import mido

# Parse the Blackbird MIDI file
midi_file = mido.MidiFile('/Users/mochi/Documents/Practice Room Chat/Midi Data/blackbird-the-beatles.mid')

print(f"Type: {midi_file.type}")
print(f"Ticks per beat: {midi_file.ticks_per_beat}")
print(f"Number of tracks: {len(midi_file.tracks)}")
print()

# Track all note events with absolute timing
events = []
tempo = 500000  # Default tempo (120 BPM)

for i, track in enumerate(midi_file.tracks):
    print(f"Track {i}: {track.name if track.name else 'Unnamed'}")
    current_tick = 0
    active_notes = {}
    
    for msg in track:
        current_tick += msg.time
        
        if msg.type == 'set_tempo':
            tempo = msg.tempo
            bpm = mido.tempo2bpm(tempo)
            print(f"  Tempo: {bpm} BPM at tick {current_tick}")
            
        elif msg.type == 'note_on' and msg.velocity > 0:
            active_notes[msg.note] = {
                'start_tick': current_tick,
                'velocity': msg.velocity
            }
            
        elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
            if msg.note in active_notes:
                start = active_notes[msg.note]['start_tick']
                duration = current_tick - start
                events.append({
                    'note': msg.note,
                    'start': start,
                    'duration': duration,
                    'velocity': active_notes[msg.note]['velocity']
                })
                del active_notes[msg.note]

# Sort events by start time
events.sort(key=lambda x: x['start'])

# Calculate how many ticks equals 30 seconds
ticks_per_beat = midi_file.ticks_per_beat
bpm = mido.tempo2bpm(tempo)
beats_per_second = bpm / 60
ticks_per_second = ticks_per_beat * beats_per_second
thirty_seconds_ticks = int(30 * ticks_per_second)

print(f"\nLimiting to first 30 seconds (approximately {thirty_seconds_ticks} ticks)")

# Filter events to first 30 seconds
events_30s = [e for e in events if e['start'] < thirty_seconds_ticks]

print(f"Total events in first 30 seconds: {len(events_30s)}")

# Filter out notes with 0 duration
events_30s_clean = [e for e in events_30s if e['duration'] > 0]

print(f"Total valid events in first 30 seconds: {len(events_30s_clean)}")

# Generate MIDI string for training data - ALL events in 30 seconds
midi_strings = []
for event in events_30s_clean:
    midi_strings.append(f"{event['note']}@{event['start']}t-{event['duration']}t")

print(f"\nMIDI string for training data ({len(events_30s_clean)} notes in 30 seconds):")
print("[MIDI:" + ",".join(midi_strings) + ":Blackbird 30sec:90]")