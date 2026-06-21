
class_name TileSetConfig
var width : int
var height : int
var tile_pixels : int
var canvas_size : Vector2i
var pixel_scale : float

enum TileType{
	NONE,
	GROUND
}

func _init(_tile_pixels:int, _canvas_size:Vector2i, _target_width : int ) -> void:
	width = _target_width
	tile_pixels = _tile_pixels
	canvas_size = _canvas_size
	# How much are the tiles are scaled up
	pixel_scale = float(_canvas_size.x) / (_target_width * _tile_pixels)
	height = ceil(canvas_size.y / (pixel_scale * _tile_pixels))

func get_tile_type(layer : TileMapLayer, pos: Vector2i) -> TileType:
	var tile_id = layer.get_cell_atlas_coords(pos)
	# print("Tile ID at position ", pos, ": ", tile_id)
	# layer.draw_string(ThemeDB.fallback_font, 128*pos,"%d" % tile_id.x)
	match tile_id:
		Vector2i(-1,-1):
			return TileType.NONE
		_:
			return TileType.GROUND

func pos_to_pixel(pos: Vector2i) -> Vector2:
	return tile_pixels * pixel_scale * (Vector2(0.5 + pos.x,0.5 + pos.y))

func pos_to_pixel_top_left(pos: Vector2i) -> Vector2:
	return tile_pixels * pixel_scale * Vector2(pos.x, pos.y)

func pixel_to_pos(coord: Vector2) -> Vector2i:
	return Vector2i(int(coord.x / (tile_pixels * pixel_scale)), int(coord.y / (tile_pixels * pixel_scale)))

## Returns [atlas_coord.x, atlas_coord.y, atlas_id]
func get_tile_graphics(layer: TileMapLayer, pos: Vector2i) -> Vector3i:
	var a: Vector2i = layer.get_cell_atlas_coords(pos)
	var b: int = layer.get_cell_source_id(pos)
	return Vector3i(a.x, a.y, b)
