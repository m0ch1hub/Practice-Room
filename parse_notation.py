#!/usr/bin/env python3

# Parse the notation data and convert to tick-based format
# Format: Bar Beat Subdivision Position | Note | Channel | Note | Velocity | Duration (Bars.Beats.Subdivisions)

notation = """
1 1 1 1      Note     1     C2     38     0 0 1 237    
1 1 3 1      Note     1     D#2     38     0 0 0 237    
1 1 4 1      Note     1     G2     38     0 0 0 237    
1 2 1 1      Note     1     A#2     38     0 2 3 92    
1 2 2 1      Note     1     D#3     38     0 0 0 237    
1 2 3 1      Note     1     G3     38     0 0 0 237    
1 2 4 1      Note     1     A#3     38     0 0 0 237    
1 3 1 1      Note     1     D#4     38     0 1 3 142    
2 1 1 1      Note     1     A#2     38     0 1 3 237    
2 2 1 1      Note     1     G4     38     0 0 1 237    
2 2 3 1      Note     1     G#4     38     0 0 1 237    
2 3 1 1      Note     1     C2     38     0 0 3 190    
2 3 1 1      Note     1     D#2     38     0 0 3 190    
2 3 1 1      Note     1     F2     38     0 0 3 190    
2 3 1 1      Note     1     A2     38     0 0 3 190    
2 3 1 1      Note     1     D4     38     0 0 3 190    
2 3 1 1      Note     1     F#4     38     0 0 3 190    
2 3 1 1      Note     1     A4     38     0 0 3 190    
2 4 1 1      Note     1     A2     38     0 0 3 190    
2 4 2 1      Note     1     D4     38     0 0 0 237    
2 4 2 1      Note     1     C5     38     0 0 0 237    
2 4 3 1      Note     1     D4     38     0 0 1 237    
2 4 3 1      Note     1     A#4     38     0 0 1 237    
3 1 1 1      Note     1     A#1     38     0 3 3 45    
3 1 1 1      Note     1     D2     38     0 3 3 45    
3 1 1 1      Note     1     F2     38     0 3 3 45    
3 1 1 1      Note     1     A2     38     0 3 3 45    
3 1 1 1      Note     1     D4     38     0 0 3 237    
3 1 1 1      Note     1     F4     38     0 0 2 0    
3 1 1 1      Note     1     A4     38     0 0 1 237    
3 1 3 1      Note     1     F4     38     0 0 1 237    
3 2 1 1      Note     1     D4     38     0 0 1 237    
3 2 3 1      Note     1     A#3     38     0 0 1 237    
3 3 1 1      Note     1     A3     38     0 0 1 237    
3 3 3 1      Note     1     A#3     38     0 0 1 237    
3 4 1 1      Note     1     A3     38     0 0 1 237    
3 4 3 1      Note     1     G3     38     0 0 1 212
"""

# Note name to MIDI number mapping
note_to_midi = {
    'C1': 24, 'C#1': 25, 'D1': 26, 'D#1': 27, 'E1': 28, 'F1': 29, 'F#1': 30, 'G1': 31, 'G#1': 32, 'A1': 33, 'A#1': 34, 'B1': 35,
    'C2': 36, 'C#2': 37, 'D2': 38, 'D#2': 39, 'E2': 40, 'F2': 41, 'F#2': 42, 'G2': 43, 'G#2': 44, 'A2': 45, 'A#2': 46, 'B2': 47,
    'C3': 48, 'C#3': 49, 'D3': 50, 'D#3': 51, 'E3': 52, 'F3': 53, 'F#3': 54, 'G3': 55, 'G#3': 56, 'A3': 57, 'A#3': 58, 'B3': 59,
    'C4': 60, 'C#4': 61, 'D4': 62, 'D#4': 63, 'E4': 64, 'F4': 65, 'F#4': 66, 'G4': 67, 'G#4': 68, 'A4': 69, 'A#4': 70, 'B4': 71,
    'C5': 72, 'C#5': 73, 'D5': 74, 'D#5': 75, 'E5': 76, 'F5': 77, 'F#5': 78, 'G5': 79, 'G#5': 80, 'A5': 81, 'A#5': 82, 'B5': 83,
    'A#1': 34, 'D♯2': 39, 'A♯2': 46, 'D♯3': 51, 'G♯4': 68, 'A♯3': 58, 'D♯4': 63, 'F♯4': 66, 'A♯4': 70, 'A♯1': 34
}

# Convert bar.beat.subdivision.ticks to total ticks
def position_to_ticks(bar, beat, subdivision, position):
    # Logic Pro uses 960 ticks per beat!
    # 4 beats per bar
    # In Logic, subdivision represents divisions of a beat
    # The 4th value (position) is in ticks (1/960th of a beat)
    
    ticks_per_beat = 960
    beats_per_bar = 4
    # Logic shows subdivisions differently - it's the division value
    # When set to 16th notes, there are 4 subdivisions per beat
    ticks_per_subdivision = ticks_per_beat // 4  # 240 for 16th notes
    
    # Convert to zero-based indexing
    bar = bar - 1
    beat = beat - 1
    subdivision = subdivision - 1
    position = position - 1  # Position within subdivision (usually 0)
    
    total_ticks = (bar * beats_per_bar * ticks_per_beat) + \
                  (beat * ticks_per_beat) + \
                  (subdivision * ticks_per_subdivision) + \
                  position
    
    return total_ticks

def duration_to_ticks(bars, beats, subdivisions, ticks):
    # Logic Pro uses 960 ticks per beat
    ticks_per_beat = 960
    beats_per_bar = 4
    
    # In Logic's Event List:
    # - bars, beats, subdivisions are the main units
    # - The last value is already in ticks (960ths of a beat)
    # - subdivisions are 16th notes (240 ticks each when 960 ticks per beat)
    ticks_per_subdivision = 240  # 960 / 4 = 240 ticks per 16th note
    
    total_ticks = (bars * beats_per_bar * ticks_per_beat) + \
                  (beats * ticks_per_beat) + \
                  (subdivisions * ticks_per_subdivision) + \
                  ticks  # This is already in ticks!
    
    return int(total_ticks)

# Parse the notation
events = []
for line in notation.strip().split('\n'):
    parts = line.split()
    if len(parts) < 10:
        continue
    
    bar = int(parts[0])
    beat = int(parts[1])
    subdivision = int(parts[2])
    position = int(parts[3])
    
    note_name = parts[6].replace('♯', '#').replace('♭', 'b')
    velocity = int(parts[7])
    
    # Duration: bars beats subdivisions ticks
    dur_bars = int(parts[8])
    dur_beats = int(parts[9])
    dur_subdivs = int(parts[10])
    dur_ticks = int(parts[11]) if len(parts) > 11 else 0
    
    # Convert note name to MIDI number
    midi_note = note_to_midi.get(note_name, 60)
    
    # Calculate start tick (in Logic's 960 ticks per beat)
    start_tick_960 = position_to_ticks(bar, beat, subdivision, position)
    
    # Calculate duration in ticks (in Logic's 960 ticks per beat)
    duration_ticks_960 = duration_to_ticks(dur_bars, dur_beats, dur_subdivs, dur_ticks)
    
    # Convert from Logic's 960 ticks per beat to our 480 ticks per beat
    start_tick = start_tick_960 // 2
    duration_ticks = duration_ticks_960 // 2
    
    events.append({
        'note': midi_note,
        'start': start_tick,
        'duration': duration_ticks,
        'velocity': velocity,
        'note_name': note_name
    })

# Sort by start time
events.sort(key=lambda x: x['start'])

# Generate the MIDI format string for training data
midi_strings = []
for event in events:
    # Add 12 to raise by an octave as requested earlier
    midi_note = event['note'] + 12
    midi_strings.append(f"{midi_note}@{event['start']}t-{event['duration']}t")

# Print the events for verification
print("Note events:")
for event in events:
    print(f"  {event['note_name']:4} (MIDI {event['note']+12:3}) starts at tick {event['start']:4}, duration {event['duration']:4} ticks")

print("\nMIDI string for training data:")
print("[MIDI:" + ",".join(midi_strings) + ":Autumn Leaves 2-5-1:120]")

print("\nSwift code for TestMIDIView:")
print("let events = [")
for event in events:
    print(f"    SoundEngine.NoteEvent(note: {event['note']+12}, startTick: {event['start']}, durationTicks: {event['duration']}),")
print("]")