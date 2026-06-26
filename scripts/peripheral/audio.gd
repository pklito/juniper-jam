class_name AudioScript
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#   0		1		2		3			4		5		6		7			8		9		10			11
#C = Do; C♯ = Do♯; D = Re; D♯ = Re♯; E = Mi; F = Fa; F♯ = Fa♯; G = Sol; G♯ = Sol♯; A = La; A♯ = La♯; B = Si; 

class Note:
	var stream : AudioStream
	var semitone : int
	func _init(_stream : AudioStream, _note : int = 0):
		stream = _stream
		semitone = _note

var NOTES = {
	"piano": [Note.new(preload("res://assets/audio/piano do.wav"), 0), 
			  Note.new(preload("res://assets/audio/piano fa.wav"), 5),
			  Note.new(preload("res://assets/audio/piano re.wav"), 2)] as Array[Note],
	"music_box" : [Note.new(preload("res://assets/audio/mb_e6_1.wav"), 4),
				   Note.new(preload("res://assets/audio/mb_e6_2.wav"), 4),
				   Note.new(preload("res://assets/audio/mb_e6_3.wav"), 4),
				   Note.new(preload("res://assets/audio/mb_e6_4.wav"), 4),
				   Note.new(preload("res://assets/audio/mb_e6_5.wav"), 4)] as Array[Note]

}
func _test_music():
	play_major_chord()

func play_note(semitones: float, notes : Array[Note] ,volume_db: float = 0.0) -> void:
	var temporary_player = AudioStreamPlayer.new()
	add_child(temporary_player)

	var note := notes.pick_random() as Note
	
	temporary_player.stream = note.stream
	temporary_player.volume_db = volume_db
	
	temporary_player.pitch_scale = pow(2.0, (semitones - note.semitone) / 12.0)
	
	# Play the note
	temporary_player.play()
	
	# Queue the player for deletion automatically once the sound finishes
	temporary_player.finished.connect(func(): temporary_player.queue_free())

## Example wrapper to play a major triad chord (C, E, G) simultaneously
func play_major_chord() -> void:
	play_note(0, NOTES.music_box)  # Root Note (e.g., C)
	play_note(4, NOTES.music_box)  # Major Third (e.g., E)
	play_note(7,NOTES.music_box)  # Perfect Fifth (e.g., G)
