extends Node2D
class_name Game
@export_group("Rules")
@export var move_rule : Globals.MoveRules = Globals.MOVE_RULE
@export var climb_rule : Globals.ClimbRules = Globals.CLIMB_RULE
@export var allow_corner_turn : bool = Globals.ALLOW_CORNER_TURN

@export_group("Music")
@export var tempo : float = 0.25

@export_group("Level config")
@export_subgroup("start")
@export var square_start_pos : Vector2i = Vector2i(6,4)
@export var square_start_dir : Utils.Dirs = Utils.Dirs.DOWN

@export var triangle_start_pos : Vector2i = Vector2i(7,4)
@export var triangle_start_dir : Utils.Dirs = Utils.Dirs.DOWN
@export var target_tiles_wide: int = 18
@export_subgroup("goal")
@export var square_goal_pos: Vector2i = Vector2i(7,4)
@export var square_goal_dir : Utils.Dirs = Utils.Dirs.DOWN

@export var triangle_goal_pos : Vector2i = Vector2i(7,4)
@export var triangle_goal_dir : Utils.Dirs = Utils.Dirs.DOWN

@export_group("Connections")
@export var tiles: TileMapLayer
@export var player_sq_node: Node2D
@export var player_tri_node: Node2D
@export var goal_sq_node: Node2D
@export var goal_tri_node: Node2D

@export_group("Faces")
@export var face_sq_main : Sprite2D
@export var face_sq_alt : Sprite2D
@export var face_sq_goal : Sprite2D

@export var face_tri_main : Sprite2D
@export var face_tri_alt : Sprite2D
@export var face_tri_goal : Sprite2D


@export var audio: AudioScript
@export var need_scaling: Array[Node2D]

@export_group("Tile configs")
@export var tile_size: int = 128
@export var canvas_width: int = 1152
@export var canvas_height: int = 648


@onready var fanfare_timer : Timer

# (0,11), (12, 15)
var undo_stack = []

func undo_move():
	if undo_stack.size() == 0:
		return
	var move = undo_stack.pop_front()
	square.pos = move[0]
	square.ground_dir = move[1]
	triangle.pos = move[2]
	triangle.ground_dir = move[3]
	square.update_graphics()
	triangle.update_graphics()
	audio.prev_verse()
	Globals.total_steps -= 1
	try_drop_and_audio()
	# AUDIO
	audio.play_note(12, audio.INSTRUMENTS.b, -20)

func try_drop_and_audio():
	if triangle.drop_if_floating() >= 0:
		audio.play_blip()

var _tc : TileSetConfig

var square : Players.PlayerSquare
var triangle : Players.PlayerTriangle

func _update_locals():
	move_rule = Globals.MOVE_RULE
	climb_rule = Globals.CLIMB_RULE
	allow_corner_turn = Globals.ALLOW_CORNER_TURN

# Update globals
func _update_globals():
	Globals.MOVE_RULE = move_rule
	Globals.CLIMB_RULE = climb_rule
	Globals.ALLOW_CORNER_TURN = allow_corner_turn

func update_faces():
	face_sq_goal.visible = square.pos == square_goal_pos
	face_tri_goal.visible = triangle.pos == triangle_goal_pos
	var leaning_on := (triangle.pos + Utils.dir_to_vec2(triangle.ground_dir)) == square.pos
	face_sq_alt.visible = not face_sq_goal.visible and leaning_on
	face_sq_main. visible = not face_sq_goal.visible and not face_sq_alt.visible
	face_tri_alt.visible = not face_tri_goal.visible and leaning_on
	face_tri_main. visible = not face_tri_goal.visible and not face_tri_alt.visible
	

	pass

var init_drop : float = 0

var steps : int = 0
# Special func
func _ready() -> void:
	steps = Globals.total_steps
	# _update_locals()
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	player_sq_node.scale = 9 * Vector2(1,1) / target_tiles_wide
	player_tri_node.scale = 9 * 2 * Vector2(1,1) / target_tiles_wide
	goal_sq_node.scale = 9 * Vector2(1,1) / target_tiles_wide
	goal_tri_node.scale = 9 * Vector2(1,1) / target_tiles_wide
	
	goal_sq_node.rotation_degrees = 90 * square_goal_dir
	goal_tri_node.rotation_degrees = 90 * triangle_goal_dir
	
	goal_sq_node.position = _tc.pos_to_pixel(square_goal_pos)
	goal_tri_node.position = _tc.pos_to_pixel(triangle_goal_pos)

	fanfare_timer = Timer.new()
	add_child(fanfare_timer)
	fanfare_timer.timeout.connect(next_level)

	if Globals.curr_level != 0:
		audio._test_music()
		
	for node in need_scaling:
		node.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = Players.PlayerSquare.new(_tc, tiles, player_sq_node, square_start_pos, square_start_dir)
	triangle = Players.PlayerTriangle.new(_tc, tiles, player_tri_node, triangle_start_pos, triangle_start_dir)
	square.link(triangle)
	square.update_graphics()
	triangle.update_graphics()

	try_drop_and_audio()
	# undo_stack.push_front([square.pos, square.ground_dir, triangle.pos, triangle.ground_dir])

var skip_held : float = 0
var reset_held : float = 0
func _process(delta: float) -> void:
	update_faces()
	if Input.is_action_just_pressed("undo"):
		undo_move()
	
	if Input.is_action_pressed("reset"):
		reset_held += delta
	else:
		reset_held = 0

	if reset_held > 2:
		Globals.reset_level()
		Globals.total_steps = steps

	if Input.is_action_pressed("skip"):
		skip_held += delta
	else:
		skip_held = 0

	if skip_held > 2:
		win()

	
# # # # MOVE LOGIC # # # #
# ====================== #

func reset_inputs():
	triangle.next_move = Utils.Dirs.DOWN
	square.next_move = Utils.Dirs.DOWN


var duration = 0.2
var time = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_update_globals()
	time += delta
	square.update_graphics_animated()
	triangle.update_graphics_animated()
	
	if square.next_move != Utils.Dirs.DOWN and triangle.next_move != Utils.Dirs.DOWN:
		# push_error("BOTH TRYING TO MOVE")
		square.move_count = 4 if square.next_move == Utils.Dirs.RIGHT else -4
		square.next_move = Utils.Dirs.DOWN
	
	if square.move_count == 0 and triangle.move_count == 0 and time >= duration:
		if triangle.next_move != Utils.Dirs.DOWN:
			triangle.move_count = 3 if triangle.next_move == Utils.Dirs.RIGHT else -3
			reset_inputs()
			undo_stack.push_front([square.pos, square.ground_dir, triangle.pos, triangle.ground_dir])
			Globals.total_steps += 1


		if square.next_move != Utils.Dirs.DOWN:
			square.move_count = 4 if square.next_move == Utils.Dirs.RIGHT else -4
			reset_inputs()
			undo_stack.push_front([square.pos, square.ground_dir, triangle.pos, triangle.ground_dir])
			Globals.total_steps += 1

			

	if time < duration or (square.move_count == 0 and triangle.move_count == 0) :
		return

	time = 0
	var note :int = 4 - absi(square.move_count)
	if square.move_count > 0:
		duration = tempo * audio.get_note(note, true)
		var hit_wall = not square.move_right(min(duration, tempo))
		audio.play(note, true, hit_wall)
		square.move_count -= 1
		try_drop_and_audio()
	elif square.move_count < 0:
		
		duration = tempo * audio.get_note(note, true)
		var hit_wall = not square.move_left(min(duration, tempo))
		audio.play(note, true, hit_wall)
		square.move_count += 1
		try_drop_and_audio()
	
	note = 3 - abs(triangle.move_count)
	if triangle.move_count > 0:
		duration = tempo * audio.get_note(note, true)
		var hit_wall = not triangle.move_right(min(duration, tempo))
		audio.play(note, false, hit_wall)
		
		triangle.move_count -= 1
	elif triangle.move_count < 0:
		duration = tempo * audio.get_note(note, true)
		var hit_wall = not triangle.move_left(min(duration, tempo))
		audio.play(note, false, hit_wall)
		
		triangle.move_count += 1
	
	if square.move_count == 0 and triangle.move_count == 0:
		audio.next_verse()
		check_win()

func next_level():
	Globals.level_int_manual_update()
	Globals.next_level()

func win():
	# audio._win()
	fanfare_timer.start(0.4)

	
func check_win():
	if square.pos == square_goal_pos and triangle.pos == triangle_goal_pos:
		win()
	pass

func _player_moved(player : Players.Player, drag_dir : Utils.Dirs):
	reset_inputs()
	if player.ground_dir == drag_dir:
		var left_wall := player.checkWallState(Utils.dir_to_vec2(player.get_left_dir()))
		var right_wall := player.checkWallState(Utils.dir_to_vec2(player.get_right_dir()))
		match [left_wall, right_wall]:
			[Players.Player.WallState.CORNER, Players.Player.WallState.CORNER]:
				return
			[Players.Player.WallState.CORNER, _]:
				drag_dir = player.get_left_dir()
			[_, Players.Player.WallState.CORNER]:
				drag_dir = player.get_right_dir()
			_:
				return

	if player.ground_dir == posmod(drag_dir + Utils.Dirs.UP, 4):
		var left_wall := player.checkWallState(Utils.dir_to_vec2(player.get_left_dir()))
		var right_wall := player.checkWallState(Utils.dir_to_vec2(player.get_right_dir()))
		match [left_wall, right_wall]:
			[Players.Player.WallState.WALL, Players.Player.WallState.WALL]:
				return
			[Players.Player.WallState.WALL, _]:
				drag_dir = player.get_left_dir()
			[_, Players.Player.WallState.WALL]:
				drag_dir = player.get_right_dir()
			_:
				return

	if drag_dir == player.get_right_dir():
		player.next_move = Utils.Dirs.RIGHT
	if drag_dir == player.get_left_dir():
		player.next_move = Utils.Dirs.LEFT


func _square_dragged(drag_vector: Vector2) -> void:
	var drag_dir = Utils.vec2_to_dir(drag_vector)

	_player_moved(square, drag_dir)



func _triangle_dragged(drag_vector: Vector2) -> void:
	var drag_dir = Utils.vec2_to_dir(drag_vector)
	# dragged d
	
	_player_moved(triangle, drag_dir)
