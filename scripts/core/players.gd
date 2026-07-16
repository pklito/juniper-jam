extends Node2D
class_name Players
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

	# movement
	var move_count : int
	var next_move : Utils.Dirs

	enum WallState{
		FLAT,
		CORNER,
		WALL,
		NONE
	}

	func get_left_dir() -> Utils.Dirs:
		return posmod(ground_dir + Utils.Dirs.LEFT, 4) as Utils.Dirs

	func get_right_dir() -> Utils.Dirs:
		return posmod(ground_dir + Utils.Dirs.RIGHT, 4) as Utils.Dirs

	func checkWallState(move_vec : Vector2i) -> WallState:
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
		 and other_player.pos != test_pos \
		 and clampi(test_pos.x, 0, tile_config.canvas_size.x - 1) == test_pos.x \
		 and clampi(test_pos.y, 0, tile_config.canvas_size.y - 1) == test_pos.y

	func _move_internal(move_vec: Vector2i) -> bool:
		var wall_state := checkWallState(move_vec)
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
	func move_left(_duration : float) -> bool:
		var test_dir = get_left_dir()
		return _move_internal(Utils.dir_to_vec2(test_dir))
	func move_right(_duration : float) -> bool:
		var test_dir = get_right_dir()
		return _move_internal(Utils.dir_to_vec2(test_dir))

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
		## # PREVENT SHORT MOVEMENTS
		reset_tween()
		if a_pos == b_pos and a_dir == b_dir:
			_do_anim_stumble(duration)
			return
		var angle_increment = SPIN_DEGREES if moved_right else -SPIN_DEGREES
		var move_vec := Utils.dir_to_vec2(posmod(a_dir + Utils.Dirs.RIGHT, 4)) if moved_right \
						else Utils.dir_to_vec2(posmod(a_dir + Utils.Dirs.LEFT, 4))
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
		
	func move_left(duration : float = 0.2) -> bool:
		_rotate_to_wall(Utils.dir_to_vec2(get_left_dir()))
		var pre_pos := pos
		var pre_dir := ground_dir
		var ret = _move_internal(Utils.dir_to_vec2(get_left_dir()))
		var post_pos := pos
		var post_dir := ground_dir
		_rotate_to_wall(Utils.dir_to_vec2(get_left_dir()))

		_do_animation(pre_pos, pre_dir, post_pos, post_dir, false, duration)
		return ret


	func move_right(duration : float = 0.2) -> bool:
		_rotate_to_wall(Utils.dir_to_vec2(get_right_dir()))
		var pre_pos := pos
		var pre_dir := ground_dir
		var ret = _move_internal(Utils.dir_to_vec2(get_right_dir()))
		var post_pos := pos
		var post_dir := ground_dir
		_rotate_to_wall(Utils.dir_to_vec2(get_right_dir()))
		_do_animation(pre_pos, pre_dir, post_pos, post_dir, true, duration)
		return ret
		
	



class PlayerTriangle extends Player:
	func _post_init():
		SPIN_DEGREES = 120

	func _pos_solid_tile(test_pos: Vector2i) -> bool:
		return super._pos_solid_tile(test_pos) or other_player.pos == test_pos
	
	func move_left(duration : float = 0.2) -> bool:
		var test_dir = get_left_dir()
		var pre_pos := pos
		var pre_dir := ground_dir
		var ret = true
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			ret = _rotate_to_wall(Utils.dir_to_vec2(test_dir))
		var post_pos := pos
		var post_dir := ground_dir
		_do_animation(pre_pos, pre_dir, post_pos, post_dir, false, duration)
		return ret

	func move_right(duration : float = 0.2) -> bool:
		var test_dir = get_right_dir()
		var pre_pos := pos
		var pre_dir := ground_dir
		var ret = true
		if not _move_internal(Utils.dir_to_vec2(test_dir)):
			ret = _rotate_to_wall(Utils.dir_to_vec2(test_dir))
		var post_pos := pos
		var post_dir := ground_dir
		_do_animation(pre_pos, pre_dir, post_pos, post_dir, true, duration)
		return ret

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

	func drop_if_floating() -> int:
		var pre_pos := pos
		var pre_dir := ground_dir
		var dist := _drop_down()
		_do_fall_animation(pre_pos, pre_dir, pos, ground_dir, dist)
		return dist

	
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
