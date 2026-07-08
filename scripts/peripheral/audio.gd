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

static func n(_semi : int, d: float) -> Note:
	return Note.new(_semi, d)

func get_note(note : int, is_square: bool):
	var notes = MOVES_NOTES_SQUARE if is_square else MOVES_NOTES_TRIANGLE
	var c = notes[verse][note] as Note
	return c.duration

func play(note : int, is_square: bool, hit_wall : bool = false) -> float:
	var notes = MOVES_NOTES_SQUARE if is_square else MOVES_NOTES_TRIANGLE
	var c = notes[verse][note] as Note
	if hit_wall:
		play_note(c.semitone, INSTRUMENTS.snare if not is_square else INSTRUMENTS.hit)
	else:
		play_note(c.semitone, INSTRUMENTS.music_box if not is_square else INSTRUMENTS.c)
	return c.duration

func next_verse():
	verse = posmod(verse + 1, min(MOVES_NOTES_SQUARE.size(),MOVES_NOTES_TRIANGLE.size() ))

func prev_verse():
	verse = posmod(verse - 1, min(MOVES_NOTES_SQUARE.size(),MOVES_NOTES_TRIANGLE.size() ))

var verse : int = 0
var MOVES_NOTES_SQUARE = [[n(5,1),	 n(6,1), n(5,1), n(8,2)],
						  [n(6,1), n(5,0.5), n(5,0.5), n(3,2)], 
						  [n(3,1),	n(5,1),n(8,1),n(6,2)],
						  [n(5,1), n(6,0.5), n(3,0.5),n(1,1)],
						  [n(1,1), n(3,1), n(1,1),n(5,1)],
						  [n(1,1.333), n(-2,0.66), n(-2,0.66),n(-4,2)],
						  [n(-4,0.4), n(-2,0.4), n(0,0.4),n(1,3)]
						  ]
var MOVES_NOTES_TRIANGLE = [[n(5,1.333),n(6,0.6666),n(8,2)],
							[n(6,1), n(5,1), n(3,2)],
							[n(5,1.333),n(8,0.6666),n(6,2)],
							[n(5,1),n(3,1),n(1,2)],
							[n(1,1.3333),n(3,0.666),n(5,2)],
							[n(1,1),n(-2,1),n(-4,2)],
							[n(-4,0.666),n(-2,0.666),n(1,2.333)]]

class Note:
	var semitone : int
	var duration : float
	func _init(_semi : int, _duration : float):
		semitone = _semi
		duration = _duration

class Instrument:
	var stream : AudioStream
	var semitone : int
	var db_offset : float
	func _init(_stream : AudioStream, _note : int = 0, _db_offset: float = 0):
		stream = _stream
		semitone = _note
		db_offset = _db_offset

var INSTRUMENTS = {
	"piano": [Instrument.new(preload("res://assets/audio/piano do.wav"), 0, -10), 
			  Instrument.new(preload("res://assets/audio/piano fa.wav"), 5, -10),
			  Instrument.new(preload("res://assets/audio/piano re.wav"), 2, -10)] as Array[Instrument],
	"a": [Instrument.new(preload("res://assets/audio/conor_a.wav"))]as Array[Instrument],
	"b": [Instrument.new(preload("res://assets/audio/conor_b.wav"))]as Array[Instrument],
	"c": [Instrument.new(preload("res://assets/audio/conor_c.wav"))]as Array[Instrument],
	"hit": [Instrument.new(preload("res://assets/audio/conor_bass_drum.wav"))]as Array[Instrument],
	"snare": [Instrument.new(preload("res://assets/audio/conor_snare.wav"))]as Array[Instrument],
	"bass": [Instrument.new(preload("res://assets/audio/conor_bass.wav"))]as Array[Instrument],


	"music_box" : [Instrument.new(preload("res://assets/audio/mb_e6_1.wav"), 4),
				   Instrument.new(preload("res://assets/audio/mb_e6_2.wav"), 4),
				   Instrument.new(preload("res://assets/audio/mb_e6_3.wav"), 4),
				   Instrument.new(preload("res://assets/audio/mb_e6_4.wav"), 4),
				   Instrument.new(preload("res://assets/audio/mb_e6_5.wav"), 4)] as Array[Instrument]

}
func _test_music():
	play_major_chord()

var tween : Tween = null
func _win():
	if tween != null:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_interval(0.15)

	tween.tween_callback(play_note.bind(1, INSTRUMENTS.b,-20))
	tween.tween_interval(0.2)
	tween.tween_callback(play_note.bind(3, INSTRUMENTS.b,-20))
	tween.tween_interval(0.2)
	tween.tween_callback(play_note.bind(5, INSTRUMENTS.b,-20))
	tween.tween_callback(play_note.bind(8, INSTRUMENTS.b,-20))
	tween.tween_interval(0.2)
	tween.tween_callback(play_note.bind(6, INSTRUMENTS.b,-20))
	tween.tween_callback(play_note.bind(10, INSTRUMENTS.b,-20))

	tween.play()

func play_note(semitones: float, notes : Array[Instrument] ,volume_db: float = 0.0) -> void:
	var temporary_player = AudioStreamPlayer.new()
	add_child(temporary_player)

	var note := notes.pick_random() as Instrument
	
	temporary_player.stream = note.stream
	temporary_player.volume_db = note.db_offset - 10
	
	temporary_player.pitch_scale = pow(2.0, (semitones - note.semitone) / 12.0)
	
	# Play the note
	temporary_player.play()
	
	# Queue the player for deletion automatically once the sound finishes
	temporary_player.finished.connect(func(): temporary_player.queue_free())

func play_blip():
	var temporary_player = AudioStreamPlayer.new()
	add_child(temporary_player)
	temporary_player.stream = preload("res://assets/audio/blip.wav")
	temporary_player.volume_db = -30
	
	temporary_player.play()
	
	# Queue the player for deletion automatically once the sound finishes
	temporary_player.finished.connect(func(): temporary_player.queue_free())


## Example wrapper to play a major triad chord (C, E, G) simultaneously
func play_major_chord() -> void:
	play_note(0, INSTRUMENTS.music_box)  # Root Instrument (e.g., C)
	play_note(4, INSTRUMENTS.music_box)  # Major Third (e.g., E)
	play_note(7,INSTRUMENTS.music_box)  # Perfect Fifth (e.g., G)
