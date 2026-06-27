extends Node

var ALLOW_CORNER_TURN = true

enum MoveRules {
	FREE_MOVEMENT,
	FREE_COPY_MOVEMENT,
	FREE_COPY_MOVEMENT_INVERSE
}

enum ClimbRules {
	FLOAT,
	FALL_DOWN,
	FALL_GROUND_DIR,
	LOCK
}

var CLIMB_RULE = ClimbRules.FLOAT
var MOVE_RULE = MoveRules.FREE_MOVEMENT

var curr_level = 0
const LEVELS = [
	"res://scenes/levels/title_screen.tscn",
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3_1.tscn",
	"res://scenes/levels/level_drop.tscn",
	"res://scenes/levels/level_4_2.tscn",
	"res://scenes/levels/level_last.tscn"

]

func current_level_path() -> String:
	return get_tree().current_scene.scene_file_path

func next_level():
	curr_level += 1
	get_tree().change_scene_to_file(LEVELS[curr_level])

func level_int_manual_update():
	for i in range(LEVELS.size()):
		if LEVELS[i] == current_level_path():
			curr_level = i
			return
	print("FAILED")

func reset_level():
	get_tree().change_scene_to_file(current_level_path())
	
