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
			ground_dir = Utils.vec2_to_dir(-move_vec)# turn around
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
	func update_rotation(going_left: bool):
		var move_dir := posmod(ground_dir + 1, 4)
		if not going_left:
			move_dir = posmod(ground_dir - 1, 4)
		var move_vec := Utils.dir_to_vec2(move_dir)
		# print(move_vec, " ", pos + move_vec, " ", move_dir, " ", _pos_open(pos + move_vec))
		if _pos_solid_tile(pos + move_vec):
			ground_dir = move_dir
	pass


class PlayerTriangle extends Player:
	func _pos_solid_tile(test_pos: Vector2i) -> bool:
		return super._pos_solid_tile(test_pos) or other_player.pos == test_pos

	func _post_check(_move_vec : Vector2i):
		if not _pos_open(pos + _move_vec):
			ground_dir = Utils.vec2_to_dir(_move_vec)
	
	func move_left() -> void:
		var test_dir = posmod(ground_dir + 1, 4)
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			_post_check(Utils.dir_to_vec2(test_dir))
	func move_right() -> void:
		var test_dir = posmod(ground_dir - 1, 4)
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			_post_check(Utils.dir_to_vec2(test_dir))

	
		


# Special func
func _ready() -> void:
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = PlayerSquare.new(_tc, tiles, player_sq_node, Vector2i(5,3), 0)
	triangle = PlayerTriangle.new(_tc, tiles, player_tri_node, Vector2i(8,5), 0)
	square.link(triangle)

	square.update_graphics()
	triangle.update_graphics()


var time = 0.0
var time2 = 0.0
var move_count : int = 4
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	square.update_graphics()
	triangle.update_graphics()
	time += delta
	time2 += delta
	if time > 0.3:
		time = 0
		if move_count <= -3:
			move_count = 4
		move_count -= 1

		if move_count >= 0:
			square.move_left()
		else:
			triangle.move_right()
	if time2 > 0.1:
		time2 = 0
		square.update_rotation(true)
