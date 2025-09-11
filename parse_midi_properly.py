#!/usr/bin/env python3
import mido

# Parse the actual MIDI file
midi_file = mido.MidiFile('/Users/mochi/Documents/Practice Room Chat/Midi Data/Autumn leaves 2-5-1 to B flat.mid')

print(f"Type: {midi_file.type}")
print(f"Ticks per beat: {midi_file.ticks_per_beat}")
print(f"Number of tracks: {len(midi_file.tracks)}")
print()

# Track all note events with absolute timing
events = []
current_tick = 0

for track in midi_file.tracks:
    print(f"Track: {track.name if track.name else 'Unnamed'}")
    current_tick = 0
    active_notes = {}  # Track which notes are currently on
    
    for msg in track:
        current_tick += msg.time  # Add delta time
        
        if msg.type == 'note_on' and msg.velocity > 0:
            # Note starts
            active_notes[msg.note] = {
                'start_tick': current_tick,
                'velocity': msg.velocity
            }
            print(f"  Note ON:  {msg.note} at tick {current_tick}, velocity {msg.velocity}")
            
        elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
            # Note ends
            if msg.note in active_notes:
                start = active_notes[msg.note]['start_tick']
                duration = current_tick - start
                events.append({
                    'note': msg.note,  # Keep original MIDI note numbers
                    'start': start,
                    'duration': duration,
                    'velocity': active_notes[msg.note]['velocity']
                })
                print(f"  Note OFF: {msg.note} at tick {current_tick}, duration {duration}")
                del active_notes[msg.note]
        
        elif msg.type == 'set_tempo':
            tempo = mido.tempo2bpm(msg.tempo)
            print(f"  Tempo: {tempo} BPM")

# Sort events by start time
events.sort(key=lambda x: x['start'])

print("\n\nParsed events for our system:")
print("let events = [")
for event in events:
    print(f"    SoundEngine.NoteEvent(note: {event['note']}, startTick: {event['start']}, durationTicks: {event['duration']}),")
print("]")

# Generate MIDI string for training data
midi_strings = []
for event in events:
    midi_strings.append(f"{event['note']}@{event['start']}t-{event['duration']}t")

print("\nMIDI string for training data:")
print("[MIDI:" + ",".join(midi_strings) + ":Autumn Leaves 2-5-1:100]")