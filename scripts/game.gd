extends Node2D
class_name Game
@export_group("Rules")
@export var move_rule : Globals.MoveRules = Globals.MOVE_RULE
@export var climb_rule : Globals.ClimbRules = Globals.CLIMB_RULE
@export var allow_corner_turn : bool = Globals.ALLOW_CORNER_TURN

@export_group("Level config")
@export var square_start_pos : Vector2i = Vector2i(6,4)
@export var triangle_start_pos : Vector2i = Vector2i(7,4)
@export var target_tiles_wide: int = 18

@export_group("Connections")
@export var tiles: TileMapLayer
@export var player_sq_node: Node2D
@export var player_tri_node: Node2D
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
	var pos : Vector2i
	var ground_dir : int = 0
	var player_node : Node2D
	var tile_config : TileSetConfig
	var tiles : TileMapLayer
	var other_player: Player
	func _init(_tile_config : TileSetConfig, _tiles : TileMapLayer, _player_node: Node2D, _pos: Vector2i, _ground_dir: int) -> void:
		pos = _pos
		ground_dir = _ground_dir
		player_node = _player_node
		tile_config = _tile_config
		tiles = _tiles

	func link(_other_player: Player):
		other_player = _other_player
		_other_player.other_player = self

	func _pos_solid_tile(test_pos: Vector2i) -> bool:
		return tile_config.get_tile_type(tiles, test_pos) != Utils.TileType.NONE
	
	func _pos_open(test_pos: Vector2i) -> bool:
		return not _pos_solid_tile(test_pos) and other_player.pos != test_pos

	func _move_internal(move_vec: Vector2i) -> bool:
		# spot on the left is open
		if not _pos_open(pos + move_vec):
			return false

		# Walk left
		if _pos_solid_tile(pos + move_vec + Utils.dir_to_vec2(ground_dir)):
			pos = pos + move_vec
			return true
		# Corner turn
		if _pos_open(pos + move_vec + Utils.dir_to_vec2(ground_dir)) and Globals.ALLOW_CORNER_TURN:
			pos = pos + move_vec + Utils.dir_to_vec2(ground_dir)
			ground_dir = Utils.vec2i_to_dir(-move_vec)# turn around
			return true
		return false
	
	func _rotate_to_wall(_move_vec : Vector2i) -> bool:
		if _pos_solid_tile(pos + _move_vec):
			ground_dir = Utils.vec2i_to_dir(_move_vec)
			return true
		return false


	func update_graphics() -> void:
		player_node.position = tile_config.pos_to_pixel(pos)
		player_node.rotation_degrees = ground_dir * 90
	func move_left() -> void:
		var test_dir = posmod(ground_dir + 1, 4)
		_move_internal(Utils.dir_to_vec2(test_dir))
	func move_right() -> void:
		var test_dir = posmod(ground_dir - 1, 4)
		_move_internal(Utils.dir_to_vec2(test_dir))


class PlayerSquare extends Player:
	func move_left() -> void:
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir + 1, 4)))
		_move_internal(Utils.dir_to_vec2(posmod(ground_dir + 1, 4)))
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir + 1, 4)))

	func move_right() -> void:
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir - 1, 4)))
		_move_internal(Utils.dir_to_vec2(posmod(ground_dir - 1, 4)))
		_rotate_to_wall(Utils.dir_to_vec2(posmod(ground_dir - 1, 4)))



class PlayerTriangle extends Player:
	func _pos_solid_tile(test_pos: Vector2i) -> bool:
		return super._pos_solid_tile(test_pos) or other_player.pos == test_pos
	
	func move_left() -> void:
		var test_dir = posmod(ground_dir + 1, 4)
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			_rotate_to_wall(Utils.dir_to_vec2(test_dir))
	func move_right() -> void:
		var test_dir = posmod(ground_dir - 1, 4)
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			_rotate_to_wall(Utils.dir_to_vec2(test_dir))

	func _drop_ground_dir(loop: int = 20):
		if loop <= 0:
			push_error("drop_if_floating: too many recursions")
			return
		var test_pos = pos + Utils.dir_to_vec2(ground_dir)
		if not _pos_solid_tile(test_pos):
			pos = test_pos
			_drop_ground_dir(loop - 1) # recursive drop until we hit a solid tile

	func _drop_down():
		var test_pos = pos + Utils.dir_to_vec2(ground_dir)
		if _pos_solid_tile(test_pos):
			return
		ground_dir = 0
		_drop_ground_dir() # recursive drop until we hit a solid tile

	func drop_if_floating():
		if Globals.CLIMB_RULE == Globals.ClimbRules.FALL_DOWN:
			_drop_down()
		if Globals.CLIMB_RULE == Globals.ClimbRules.FALL_GROUND_DIR:
			_drop_ground_dir()
	
# Special func
func _ready() -> void:
	# _update_locals()
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	player_sq_node.scale = _tc.pixel_scale * Vector2(1,1)
	player_tri_node.scale = 2 * _tc.pixel_scale * Vector2(1,1)

	for node in need_scaling:
		node.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = PlayerSquare.new(_tc, tiles, player_sq_node, square_start_pos, 0)
	triangle = PlayerTriangle.new(_tc, tiles, player_tri_node, triangle_start_pos, 0)
	square.link(triangle)

	square.update_graphics()
	triangle.update_graphics()


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
	square.update_graphics()
	triangle.update_graphics()
	
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

	
