extends Node2D
class_name Game
@export_group("Rules")
@export var move_rule : Globals.MoveRules = Globals.MOVE_RULE
@export var climb_rule : Globals.ClimbRules = Globals.CLIMB_RULE
@export var allow_corner_turn : bool = Globals.ALLOW_CORNER_TURN

@export_group("Level config")
@export var square_start_pos : Vector2i = Vector2i(6,4)
@export var square_start_dir : Utils.Dirs = Utils.Dirs.DOWN

@export var triangle_start_pos : Vector2i = Vector2i(7,4)
@export var triangle_start_dir : Utils.Dirs = Utils.Dirs.DOWN
@export var target_tiles_wide: int = 18

@export_group("Connections")
@export var tiles: TileMapLayer
@export var player_sq_node: Node2D
@export var player_tri_node: Node2D
@export var audio: AudioScript
@export var need_scaling: Array[Node2D]

@export_group("Tile configs")
@export var tile_size: int = 128
@export var canvas_width: int = 1152
@export var canvas_height: int = 648

# (0,11), (12, 15)

var _tc : TileSetConfig

var square : Player
var triangle : Player

func _update_locals():
	move_rule = Globals.MOVE_RULE
	climb_rule = Globals.CLIMB_RULE
	allow_corner_turn = Globals.ALLOW_CORNER_TURN

# Update globals
func _update_globals():
	Globals.MOVE_RULE = move_rule
	Globals.CLIMB_RULE = climb_rule
	Globals.ALLOW_CORNER_TURN = allow_corner_turn

# Players
class Player:
	var SPIN_DEGREES : float
	var anim_angle: float = 0.0
	var anim_floor_angle: float = 0.0
	var tween : Tween
	var pos : Vector2i
	var prev_pos : Vector2i
	var ground_dir : int = 0
	var player_node : Node2D
	var tile_config : TileSetConfig
	var tiles : TileMapLayer
	var other_player: Player
	var pivot_node : Node2D

	enum WallState{
		FLAT,
		CORNER,
		WALL,
		NONE
	}

	func checkWallState(pos : Vector2i, move_vec : Vector2i) -> WallState:
		# spot on the left is not open (no movement can be done)
		if not _pos_open(pos + move_vec):
			if _pos_solid_tile(pos + move_vec):
				return WallState.WALL
			return WallState.NONE

		# Walk left
		if _pos_solid_tile(pos + move_vec + Utils.dir_to_vec2(ground_dir)):
			return WallState.FLAT
		# Corner turn
		if _pos_open(pos + move_vec + Utils.dir_to_vec2(ground_dir)) and Globals.ALLOW_CORNER_TURN:
			return WallState.CORNER
		return WallState.NONE



	func _post_init():
		pass

	func _init(_tile_config : TileSetConfig, _tiles : TileMapLayer, _player_node: Node2D, _pos: Vector2i, _ground_dir: int) -> void:
		pos = _pos
		ground_dir = _ground_dir
		player_node = _player_node
		tile_config = _tile_config
		tiles = _tiles
		pivot_node = player_node.get_node(str(player_node.get_path()) + "/pivot")

		_post_init()

	func link(_other_player: Player):
		other_player = _other_player
		_other_player.other_player = self

	func _pos_solid_tile(test_pos: Vector2i) -> bool:
		return tile_config.get_tile_type(tiles, test_pos) == Utils.TileType.GROUND
	
	func _pos_open(test_pos: Vector2i) -> bool:
		return tile_config.get_tile_type(tiles, test_pos) == Utils.TileType.NONE \
		 and other_player.pos != test_pos

	func _move_internal(move_vec: Vector2i) -> bool:
		var wall_state := checkWallState(pos, move_vec)
		# spot on the left is open
		if not _pos_open(pos + move_vec):
			return false
		match wall_state:
			WallState.FLAT:
				pos = pos + move_vec
				return true
			WallState.CORNER:
				pos = pos + move_vec + Utils.dir_to_vec2(ground_dir)
				ground_dir = Utils.vec2i_to_dir(-move_vec)# turn around
				return true
			_: # WALL, NONE
				return false

	
	func _rotate_to_wall(_move_vec : Vector2i) -> bool:
		if _pos_solid_tile(pos + _move_vec):
			ground_dir = Utils.vec2i_to_dir(_move_vec)
			return true
		return false

	func reset_tween():
		if tween != null:
			tween.kill()
		tween = player_node.create_tween()
		tween.bind_node(player_node)
		
	func is_moving() -> bool:
		return pos != prev_pos
	
	func update_graphics_animated():
		pass
	
	func _finish_move():
		# update_graphics()
		prev_pos = pos
		player_node.position = tile_config.pos_to_pixel(pos)

	func update_graphics() -> void:
		prev_pos = pos
		player_node.position = tile_config.pos_to_pixel(pos)
		player_node.rotation_degrees = ground_dir * 90
		anim_floor_angle = ground_dir * 90
	func move_left() -> void:
		var test_dir = posmod(ground_dir + 1, 4)
		_move_internal(Utils.dir_to_vec2(test_dir))
	func move_right() -> void:
		var test_dir = posmod(ground_dir - 1, 4)
		_move_internal(Utils.dir_to_vec2(test_dir))

	func _do_anim_stumble(duration : float = 0.2):
		reset_tween()
		var p_b := player_node.position
		tween.set_trans(Tween.TRANS_BOUNCE)
		var shake_dir := Vector2(10, 0).rotated(90*ground_dir)
		tween.tween_property(player_node, "position", p_b - shake_dir, duration/4)
		tween.parallel().tween_property(pivot_node, "rotation_degrees", anim_angle-20, duration/4)
		
		tween.tween_property(player_node, "position", p_b + shake_dir, duration/4)
		tween.parallel().tween_property(pivot_node, "rotation_degrees", anim_angle+20, duration/4)
		
		tween.tween_property(player_node, "position", p_b, duration/4)
		tween.parallel().tween_property(pivot_node, "rotation_degrees", anim_angle, duration/4)
		
		tween.tween_callback(self._finish_move)

		

	func _do_animation(a_pos : Vector2i, a_dir : int, b_pos : Vector2i, b_dir : Utils.Dirs, moved_right : bool, duration : float = 0.2):
		reset_tween()
		if a_pos == b_pos and a_dir == b_dir:
			_do_anim_stumble(duration)
			return
		var angle_increment = SPIN_DEGREES if moved_right else -SPIN_DEGREES
		var move_vec := Utils.dir_to_vec2(posmod(a_dir - 1, 4)) if moved_right \
						else Utils.dir_to_vec2(posmod(a_dir + 1, 4))
		if b_dir == a_dir:
			anim_angle += angle_increment
			
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(player_node, "global_position", tile_config.pos_to_pixel(b_pos), duration)
			tween.parallel()
			tween.tween_property(pivot_node, "rotation_degrees", anim_angle, duration)
			tween.parallel().tween_property(player_node, "rotation_degrees", anim_floor_angle, duration)

			tween.tween_callback(self._finish_move)
			return

		# triangle only
		if a_pos == b_pos:
			anim_angle += 120 if moved_right else -120
			anim_floor_angle += -90 if moved_right else 90
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(player_node, "global_position", tile_config.pos_to_pixel(b_pos), duration)
			tween.parallel()
			tween.tween_property(pivot_node, "rotation_degrees", anim_angle, duration)
			tween.parallel().tween_property(player_node, "rotation_degrees", anim_floor_angle, duration)
			tween.tween_callback(self._finish_move)
			return

		# big corner
		anim_angle += angle_increment
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(pivot_node, "rotation_degrees", anim_angle, duration/2)
		tween.parallel().tween_property(player_node, "rotation_degrees", anim_floor_angle, duration/2)
		tween.parallel().tween_property(player_node, "global_position", tile_config.pos_to_pixel(a_pos + move_vec), duration/2)
		anim_floor_angle += 90 if moved_right else -90
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(pivot_node, "rotation_degrees", anim_angle, duration/2)
		tween.parallel().tween_property(player_node, "rotation_degrees", anim_floor_angle, duration/2)
		tween.parallel().tween_property(player_node, "global_position", tile_config.pos_to_pixel(b_pos), duration/2)

		
		tween.tween_callback(self._finish_move)
		return


class PlayerSquare extends Player:
	func _post_init():
		SPIN_DEGREES = 90
		
	func move_left() -> void:
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir + 1, 4)))
		var pre_pos := pos
		var pre_dir := ground_dir
		_move_internal(Utils.dir_to_vec2(posmod(ground_dir + 1, 4)))
		var post_pos := pos
		var post_dir := ground_dir
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir + 1, 4)))

		_do_animation(pre_pos, pre_dir, post_pos, post_dir, false)


	func move_right() -> void:
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir - 1, 4)))
		var pre_pos := pos
		var pre_dir := ground_dir
		_move_internal(Utils.dir_to_vec2(posmod(ground_dir - 1, 4)))
		var post_pos := pos
		var post_dir := ground_dir
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir - 1, 4)))
		_do_animation(pre_pos, pre_dir, post_pos, post_dir, true)
		
	



class PlayerTriangle extends Player:
	func _post_init():
		SPIN_DEGREES = 120

	func _pos_solid_tile(test_pos: Vector2i) -> bool:
		return super._pos_solid_tile(test_pos) or other_player.pos == test_pos
	
	func move_left() -> void:
		var test_dir = posmod(ground_dir + 1, 4)
		var pre_pos := pos
		var pre_dir := ground_dir
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			_rotate_to_wall(Utils.dir_to_vec2(test_dir))
		var post_pos := pos
		var post_dir := ground_dir
		_do_animation(pre_pos, pre_dir, post_pos, post_dir, false)

	func move_right() -> void:
		var test_dir = posmod(ground_dir - 1, 4)
		var pre_pos := pos
		var pre_dir := ground_dir
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			_rotate_to_wall(Utils.dir_to_vec2(test_dir))
		var post_pos := pos
		var post_dir := ground_dir
		_do_animation(pre_pos, pre_dir, post_pos, post_dir, true)

	func _drop_ground_dir(loop: int = 20) -> int:
		if loop <= 0:
			push_error("drop_if_floating: too many recursions")
			return 0
		var test_pos = pos + Utils.dir_to_vec2(ground_dir)
		if not _pos_solid_tile(test_pos):
			pos = test_pos
			return 1 + _drop_ground_dir(loop - 1) # recursive drop until we hit a solid tile
		return 0

	func _drop_down() -> int:
		var test_pos = pos + Utils.dir_to_vec2(ground_dir)
		if _pos_solid_tile(test_pos):
			return -1
		ground_dir = 0
		return _drop_ground_dir() # recursive drop until we hit a solid tile

	func drop_if_floating():
		var pre_pos := pos
		var pre_dir := ground_dir
		if Globals.CLIMB_RULE == Globals.ClimbRules.FALL_DOWN:
			var dist := _drop_down()
			_do_fall_animation(pre_pos, pre_dir, pos, ground_dir, dist)
		if Globals.CLIMB_RULE == Globals.ClimbRules.FALL_GROUND_DIR:
			var dist := _drop_ground_dir()
			_do_fall_animation(pre_pos, pre_dir, pos, ground_dir, dist)

	
	func _do_fall_animation(_a_pos : Vector2i, a_dir : Utils.Dirs, b_pos : Vector2i, b_dir : Utils.Dirs, fall : int):
		if fall < 0 or (a_dir == b_dir and fall == 0):
			return
		anim_floor_angle = Utils.near_mod(b_dir, a_dir, 4) * 90
		var rotate_delay := 0.05
		var rotate_time := sqrt(fall)/2 - rotate_delay
		if fall == 0:
			rotate_delay = 0
			rotate_time = 0.3
		
		reset_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(player_node, "global_position", tile_config.pos_to_pixel(b_pos), sqrt(fall)/2)
		tween.set_trans(Tween.TRANS_SPRING)
		tween.parallel().tween_property(player_node, "rotation_degrees", anim_floor_angle, rotate_time).from(a_dir * 90).set_delay(rotate_delay)


	
# Special func
func _ready() -> void:
	# _update_locals()
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	player_sq_node.scale = 9 * Vector2(1,1) / target_tiles_wide
	player_tri_node.scale = 9 * 2 * Vector2(1,1) / target_tiles_wide

	for node in need_scaling:
		node.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = PlayerSquare.new(_tc, tiles, player_sq_node, square_start_pos, square_start_dir)
	triangle = PlayerTriangle.new(_tc, tiles, player_tri_node, triangle_start_pos, triangle_start_dir)
	square.link(triangle)
	audio._test_music()
	square.update_graphics()
	triangle.update_graphics()


# # # # MOVE LOGIC # # # #
# ====================== #

var time = 0.0
var time2 = 0.0
var move_count_sq : int = 0
var move_count_tri : int = 0
var tri_wait_move : bool = false
var sq_wait_move : bool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_update_globals()
	time += delta
	time2 += delta
	square.update_graphics_animated()
	triangle.update_graphics_animated()
	
	if time < 0.3:
		return

	if move_count_sq == 0:
		tri_wait_move = false
	if move_count_tri == 0:
		sq_wait_move = false
	
	if sq_wait_move and tri_wait_move:
		push_error("MUTEX on waits")
		sq_wait_move = false
		tri_wait_move = false
	
	time = 0
	if move_count_sq > 0 and not sq_wait_move:
		square.move_right()
		move_count_sq -= 1
		triangle.drop_if_floating()
	elif move_count_sq < 0 and not sq_wait_move:
		square.move_left()
		move_count_sq += 1
		triangle.drop_if_floating()
	
	if move_count_tri > 0 and not tri_wait_move:
		triangle.move_right()
		move_count_tri -= 1
	elif move_count_tri < 0 and not tri_wait_move:
		triangle.move_left()
		move_count_tri += 1

func _square_dragged(drag_vector: Vector2) -> void:
	# Triangle on square rn and rule says lock
	if Globals.CLIMB_RULE == Globals.ClimbRules.LOCK and triangle.pos + Utils.dir_to_vec2(triangle.ground_dir) == square.pos:
		return

	# Currently moving
	if move_count_sq != 0:
		return
	
	var drag_dir = Utils.vec2_to_dir(drag_vector)
	if square.ground_dir == drag_dir or square.ground_dir == posmod(drag_dir + 2, 4):
		return
	if drag_dir == posmod(square.ground_dir - 1, 4):
		move_count_sq = 4
	if drag_dir == posmod(square.ground_dir + 1, 4):
		move_count_sq = -4

	if Globals.MOVE_RULE != Globals.MoveRules.FREE_COPY_MOVEMENT and \
	Globals.MOVE_RULE != Globals.MoveRules.FREE_COPY_MOVEMENT_INVERSE:
		return
	var mult : int = 1
	if Globals.MOVE_RULE == Globals.MoveRules.FREE_COPY_MOVEMENT_INVERSE:
		mult = -1
	tri_wait_move = true
	if drag_dir == posmod(square.ground_dir - 1, 4):
		move_count_tri = 3 * mult
	if drag_dir == posmod(square.ground_dir + 1, 4):
		move_count_tri = -3 * mult


func _triangle_dragged(drag_vector: Vector2) -> void:
	# Currently moving
	if move_count_tri != 0:
		return

	var drag_dir = Utils.vec2_to_dir(drag_vector)
	# dragged up.
	if triangle.ground_dir == drag_dir or triangle.ground_dir == posmod(drag_dir + 2, 4):
		return

	if drag_dir == posmod(triangle.ground_dir - 1, 4):
		move_count_tri = 3
	if drag_dir == posmod(triangle.ground_dir + 1, 4):
		move_count_tri = -3

	if Globals.MOVE_RULE != Globals.MoveRules.FREE_COPY_MOVEMENT and \
	Globals.MOVE_RULE != Globals.MoveRules.FREE_COPY_MOVEMENT_INVERSE:
		return
	var mult : int = 1
	if Globals.MOVE_RULE == Globals.MoveRules.FREE_COPY_MOVEMENT_INVERSE:
		mult = -1
	sq_wait_move = true
	if drag_dir == posmod(triangle.ground_dir - 1, 4):
		move_count_sq = 4 * mult
	if drag_dir == posmod(triangle.ground_dir + 1, 4):
		move_count_sq = -4 * mult
