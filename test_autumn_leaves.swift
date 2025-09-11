import Foundation

// Test script to verify Autumn Leaves 2-5-1 playback timing
// The expected MIDI data from training:
// [MIDI:36@0t-594t,39@240t-474t,43@360t-474t,46@480t-1504t,51@600t-474t,55@720t-474t,58@840t-474t,63@960t-1124t,46@1920t-1314t,67@2400t-594t,68@2640t-594t,36@2880t-740t,39@2880t-740t,41@2880t-740t,45@2880t-740t,62@2880t-740t,66@2880t-740t,69@2880t-740t,45@3360t-740t,62@3480t-474t,72@3480t-474t,62@3600t-594t,70@3600t-594t,34@3840t-1890t,38@3840t-1890t,41@3840t-1890t,45@3840t-1890t,62@3840t-834t,65@3840t-240t,69@3840t-594t,65@4080t-594t,62@4320t-594t,58@4560t-594t,57@4800t-594t,58@5040t-594t,57@5280t-594t,55@5520t-544t:Autumn Leaves 2-5-1:100]

// Key timings to verify:
// Tick 0: C2 (MIDI 36) starts - Cm7 chord root
// Tick 240: Eb2 (MIDI 39) starts
// Tick 360: G2 (MIDI 43) starts  
// Tick 480: Bb2 (MIDI 46) starts
// ...
// Tick 2880: F7 chord - 7 notes start simultaneously (36,39,41,45,62,66,69)
// This is the critical test - all these notes must play at exactly the same time
// Tick 3840: BbMaj7 chord - 7 notes start simultaneously (34,38,41,45,62,65,69)

print("""
Testing Autumn Leaves 2-5-1 Progression
======================================

Expected behavior at 100 BPM (600ms per beat):

1. Cm7 chord (0-2.88s):
   - Quick arpeggio: C2, Eb2, G2
   - Then Bb2, Eb3, G3, Bb3, Eb4 ascending
   - Bb2 continues through to F7

2. F7 chord (2.88s): 
   - **CRITICAL**: 7 notes must start EXACTLY together
   - C2, Eb2, F2, A2, D4, F#4, A4
   - This is where timer-based playback failed

3. BbMaj7 chord (3.84s):
   - 7 notes start together
   - Bb1, D2, F2, A2, D4, F4, A4
   
If the F7 and BbMaj7 chords sound "cramped" or notes don't 
start simultaneously, the MIDI sequencer is not working correctly.

To test:
1. Open the app
2. Type: "What is a 2-5-1?"
3. Listen carefully to the audio playback
4. The F7 chord at 2.88s should have all notes attack together
""")