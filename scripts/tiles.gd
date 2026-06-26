
class_name TileSetConfig
var width : int
var height : int
var tile_pixels : int
var canvas_size : Vector2i
var pixel_scale : float

static func calculate_pixel_scale(_tile_pixels:int, _canvas_size:Vector2i, _target_width : int ) -> float:
	return float(_canvas_size.x) / (_target_width * _tile_pixels)

func _init(_tile_pixels:int, _canvas_size:Vector2i, _target_width : int ) -> void:
	width = _target_width
	tile_pixels = _tile_pixels
	canvas_size = _canvas_size
	# How much are the tiles are scaled up
	pixel_scale = calculate_pixel_scale(_tile_pixels, _canvas_size, _target_width)
	height = ceil(canvas_size.y / (pixel_scale * _tile_pixels))

func get_tile_type(layer : TileMapLayer, pos: Vector2i) -> Utils.TileType:
	var tile_id = layer.get_cell_atlas_coords(pos)
	# print("Tile ID at position ", pos, ": ", tile_id)
	# layer.draw_string(ThemeDB.fallback_font, 128*pos,"%d" % tile_id.x)
	var slanted_floors := [[0, 9], [0, 15], [1, 15], [2, 12], [4, 15], [6, 10], [7, 10], [8, 13], [9, 13], [10, 10], [10, 16], [11, 16], [12, 13], [14, 16], [14, 8], [15, 8], [16, 11], [17, 11]]
	for fl in slanted_floors:
		if tile_id.x == fl[0] and tile_id.y == fl[1]:
			return Utils.TileType.OBSTACLE
	if tile_id == Vector2i(-1,-1):
		return Utils.TileType.NONE
	elif layer.get_cell_source_id(pos) == 0 and ( range(8,16).has(tile_id.y) or (tile_id.x >= 12 and tile_id.y == 7)):
		return Utils.TileType.GROUND
	elif layer.get_cell_source_id(pos) != 0:
		return Utils.TileType.GROUND
	else:
		return Utils.TileType.OBSTACLE

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
