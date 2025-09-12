#!/usr/bin/env python3
import mido
import sys

def parse_midi_to_training_format(filepath):
    """Parse MIDI file and convert to training data format"""
    mid = mido.MidiFile(filepath)
    
    # Collect all note events with absolute time
    events = []
    current_time = 0
    
    for msg in mid:
        current_time += msg.time
        if msg.type == 'note_on' and msg.velocity > 0:
            # Convert seconds to ticks (assuming 960 ticks per beat, 120 BPM)
            ticks = int(current_time * 960 * 2)  # 2 beats per second at 120 BPM
            events.append((ticks, 'on', msg.note))
        elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
            ticks = int(current_time * 960 * 2)
            events.append((ticks, 'off', msg.note))
    
    # Group notes that start together
    note_groups = []
    current_group = []
    current_start = None
    
    for i, (time, event_type, note) in enumerate(events):
        if event_type == 'on':
            if current_start is None or abs(time - current_start) < 10:  # Within 10 ticks
                if current_start is None:
                    current_start = time
                current_group.append((note, time))
            else:
                if current_group:
                    note_groups.append((current_start, current_group))
                current_group = [(note, time)]
                current_start = time
    
    if current_group:
        note_groups.append((current_start, current_group))
    
    # Find end times for each note
    note_ends = {}
    for time, event_type, note in events:
        if event_type == 'off':
            note_ends[note] = time
    
    # Build MIDI string
    midi_parts = []
    for start_time, notes in note_groups[:15]:  # Limit to first 15 groups for training
        for note, actual_start in notes:
            end_time = note_ends.get(note, actual_start + 960)  # Default to quarter note
            midi_parts.append(f"{note}@{actual_start}t-{end_time}t")
    
    return ",".join(midi_parts)

# Parse the MIDI file
try:
    midi_string = parse_midi_to_training_format("/Users/mochi/Documents/Practice Room Chat/Midi Data/251 b flat.mid")
    print("MIDI string for training data:")
    print(f"[MIDI:{midi_string}:2-5-1 in B flat]")
except Exception as e:
    print(f"Error: {e}")
    print("\nTrying simpler format...")
    
    # Fallback: Just extract the chord notes
    # Cm7: C(48) Eb(51) G(55) Bb(58)
    # F7: F(53) A(57) C(60) Eb(63)
    # BbMaj7: Bb(58) D(62) F(65) A(69)
    
    # Simple version with just the chord tones
    simple = "48@0t-960t,51@0t-960t,55@0t-960t,58@0t-960t,53@960t-1920t,57@960t-1920t,60@960t-1920t,63@960t-1920t,58@1920t-2880t,62@1920t-2880t,65@1920t-2880t,69@1920t-2880t"
    print(f"[MIDI:{simple}:2-5-1 in B flat]")