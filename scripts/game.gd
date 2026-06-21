extends Node2D

@export_group("Tile configs")
@export var tiles: TileMapLayer
@export var tile_size: int = 128
@export var canvas_width: int = 1152
@export var canvas_height: int = 648
@export var target_tiles_wide: int = 18

enum TileType{
	NONE,
	GROUND
}
var _tile_config : TileSetConfig
class TileSetConfig:
	var width : int
	var height : int
	var tile_pixels : int
	var canvas_size : Vector2i
	var pixel_scale : float

	func _init(_tile_pixels:int, _canvas_size:Vector2i, _target_width : int ) -> void:
		width = _target_width
		tile_pixels = _tile_pixels
		canvas_size = _canvas_size
		pixel_scale = float(_canvas_size.x) / (_target_width * _tile_pixels)
		height = ceil(canvas_size.y / (pixel_scale * _tile_pixels))
	
	func get_tile_type(layer : TileMapLayer, pos: Vector2i) -> TileType:
		var tile_id = layer.get_cell_atlas_coords(pos)
		print("Tile ID at position ", pos, ": ", tile_id)
		match tile_id:
			Vector2i(-1,-1):
				return TileType.NONE
			_:
				return TileType.GROUND

# Special func
func _ready() -> void:
	# setup
	_tile_config = TileSetConfig.new(tile_size, Vector2i(canvas_width, canvas_height), target_tiles_wide)
	tiles.scale = _tile_config.pixel_scale * Vector2(1,1)
	
	for x in range(_tile_config.width):
		for y in range(_tile_config.height):
			var tile_type = _tile_config.get_tile_type(tiles, Vector2i(x,y))
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
