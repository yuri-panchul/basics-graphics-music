# Yesterday
import musicalbeeps

player = musicalbeeps.Player(volume = 0.5, mute_output = False)

print("tact 1")
player.play_note("G4", 0.5)
player.play_note("F4", 0.5)
player.play_note("F4", 3.0)

print("tact 2")
player.play_note("pause", 1.0)
player.play_note("A4", 0.5)
player.play_note("B4", 0.5)
player.play_note("C5#",0.5)
player.play_note("D5", 0.5)
player.play_note("E5", 0.5)
player.play_note("F5", 0.5)

print("tact 3")
player.play_note("E5", 1.5)
player.play_note("D5", 0.5)
player.play_note("D5", 2.0)

print("tact 4")
player.play_note("pause", 1.0)
player.play_note("D5", 0.5)
player.play_note("D5", 0.5)
player.play_note("C5", 0.5)
player.play_note("B4b",0.5)
player.play_note("A4", 0.5)
player.play_note("G4", 0.5)

print("tact 5")
player.play_note("B4b",1.0)
player.play_note("A4", 0.5)
player.play_note("A4", 1.5)
player.play_note("G4", 1.0)

player.play_note("pause", 3.0)
