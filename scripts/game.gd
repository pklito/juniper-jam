extends Node2D

@export_group("Connections")
@export var tiles: TileMapLayer
@export var player_sq_node: Node2D
@export var player_tri_node: Node2D

@export_group("Tile configs")
@export var tile_size: int = 128
@export var canvas_width: int = 1152
@export var canvas_height: int = 648
@export var target_tiles_wide: int = 18

var square_start_pos = Vector2i(6,4)
var triangle_start_pos = Vector2i(7,4)
# (0,11), (12, 15)

var _tc : TileSetConfig

var square : Player
var triangle : Player

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

	
		


# Special func
func _ready() -> void:
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = PlayerSquare.new(_tc, tiles, player_sq_node, square_start_pos, 0)
	triangle = PlayerTriangle.new(_tc, tiles, player_tri_node, triangle_start_pos, 0)
	square.link(triangle)

	square.update_graphics()
	triangle.update_graphics()


var time = 0.0
var time2 = 0.0
var move_count_sq : int = 0
var move_count_tri : int = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time += delta
	time2 += delta
	square.update_graphics()
	triangle.update_graphics()
	
	if time < 0.3:
		return
	
	time = 0
	if move_count_sq > 0:
		square.move_right()
		move_count_sq -= 1
	elif move_count_sq < 0:
		square.move_left()
		move_count_sq += 1
	
	if move_count_tri > 0:
		triangle.move_right()
		move_count_tri -= 1
	elif move_count_tri < 0:
		triangle.move_left()
		move_count_tri += 1
	


func _square_dragged(drag_vector: Vector2) -> void:
	var drag_dir = Utils.vec2_to_dir(drag_vector)
	if square.ground_dir == drag_dir or square.ground_dir == posmod(drag_dir + 2, 4):
		return
	if drag_dir == posmod(square.ground_dir - 1, 4):
		move_count_sq = 4
	if drag_dir == posmod(square.ground_dir + 1, 4):
		move_count_sq = -4


func _triangle_dragged(drag_vector: Vector2) -> void:
	var drag_dir = Utils.vec2_to_dir(drag_vector)
	if triangle.ground_dir == drag_dir or triangle.ground_dir == posmod(drag_dir + 2, 4):
		return
	if drag_dir == posmod(triangle.ground_dir - 1, 4):
		move_count_tri = 3
	if drag_dir == posmod(triangle.ground_dir + 1, 4):
		move_count_tri = -3
