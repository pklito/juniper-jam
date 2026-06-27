@tool
extends Node2D

@export_tool_button("Update world", "Button") 
var my_button = _on_button_pressed

@export var game : Game
var _tc : TileSetConfig

var square : Game.Player
var triangle : Game.Player
var tiles : TileMapLayer

# 2. Define the function you want to execute
func _on_button_pressed():
	print("The inspector button was clicked!")
	tiles = game.tiles
	# _update_locals()
	# setup
	_tc = TileSetConfig.new(game.tile_size, Vector2i(game.canvas_width, game.canvas_height), game.target_tiles_wide)
	tiles.scale = _tc.pixel_scale * Vector2(1,1)
	
	square = Game.PlayerSquare.new(_tc, tiles, game.player_sq_node, game.square_start_pos, game.square_start_dir)
	triangle = Game.PlayerTriangle.new(_tc, tiles, game.player_tri_node, game.triangle_start_pos, game.triangle_start_dir)
	game.player_sq_node.scale = 9 *  Vector2(1,1) / _tc.target_width
	game.player_tri_node.scale = 9 * 2 *  Vector2(1,1) / _tc.target_width
	game.goal_sq_node.scale = 9 * Vector2(1,1) / game.target_tiles_wide
	game.goal_tri_node.scale = 9 * Vector2(1,1) / game.target_tiles_wide
	game.goal_sq_node.rotation = 90 * game.square_goal_dir
	game.goal_tri_node.rotation = 90 * game.triangle_goal_dir
	
	
	game.goal_sq_node.position = _tc.pos_to_pixel(game.square_goal_pos)
	game.goal_tri_node.position = _tc.pos_to_pixel(game.triangle_goal_pos)
	#var array := []
	#for a in tiles.get_used_cells():
		#var res = tiles.get_cell_atlas_coords(a)
		#array.append(res)
	#
	#print(array)
	
	
	for node in game.need_scaling:
		if node:
			node.scale = _tc.pixel_scale * Vector2(1,1)
	square.update_graphics()
	triangle.update_graphics()
