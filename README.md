This is a Godot game I made by myself for the [Very serious Juniper game jam](https://itch.io/jam/theveryseriousjuniperdevgamejam).
The code is not particularly well organized, but feel free to see through it.

## Noteworthy features:
- MIDI-like Dynamic music playing
- Level loading
- Grid logic and controls
- Two character action queue system

Elaborated: Instead of using full audio clips, I found single note WAV files, wrote my own sheet music and had it sync up to the characters movement in the game.
This is a typical puzzle game, where there are many levels with shared assets, and you go into one once you finish the previous. I didn't do this optimally by any means, but it's a simple solution you could copy for your own game jams.
Grid logic for two different characters that move it differently, I pretty much handled all the logic from scratch.
Lots of usage of TileSetLayers
Input buffering + preventing the characters from moving when another is already moving. I was going to make this more complicated and allow them to move if they aren't in the way of the other agent, but it wasn't important enough for the jam.

The game is [playable here](https://pklito.itch.io/spin-twins)
