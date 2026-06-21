extends Node2D

@export_group("Connections")
@export var tiles: TileMapLayer
@export var player_sq: Node2D
@export var player_tri: Node2D


@export_group("Tile configs")
@export var tile_size: int = 128
@export var canvas_width: int = 1152
@export var canvas_height: int = 648
@export var target_tiles_wide: int = 18

# (0,11), (12, 15)

var _tc : TileSetConfig

# Special func
func _ready() -> void:
	# setup
	_tc = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	
	player_sq.position = _tc.pos_to_pixel(Vector2i(5,3))
	player_tri.position = _tc.pos_to_pixel(Vector2i(8,5))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
