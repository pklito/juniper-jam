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
	func _init(_tile_config : TileSetConfig, _tiles : TileMapLayer, _player_node: Node2D, _pos: Vector2i, _ground_dir: int) -> void:
		pos = _pos
		ground_dir = _ground_dir
		player_node = _player_node
		tile_config = _tile_config
		tiles = _tiles

	func _move_internal(move_vec: Vector2i) -> void:
		if tile_config.get_tile_type(tiles, pos + move_vec) == Utils.TileType.NONE:
			pos = pos + move_vec
			if tile_config.get_tile_type(tiles, pos + move_vec) != Utils.TileType.NONE:
				ground_dir = Utils.vec2_to_dir(move_vec)

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
	pass

class PlayerTriangle extends Player:
	pass

# Special func
func _ready() -> void:
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = PlayerSquare.new(_tc, tiles, player_sq_node, Vector2i(5,3), 0)
	triangle = PlayerTriangle.new(_tc, tiles, player_tri_node, Vector2i(8,5), 0)
	
	square.update_graphics()
	triangle.update_graphics()
var time = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	square.update_graphics()
	triangle.update_graphics()
	time += delta
	if time > 1:
		time = 0
		square.move_left()
		# triangle.move_right()
