extends Node2D

@export_group("Tile configs")
@export var tiles: TileMapLayer
@export var tile_size: int = 128
@export var canvas_width: int = 1152
@export var canvas_height: int = 648


@export var target_tiles_wide: int = 18
@onready var target_tiles_high: int = ceil(target_tiles_wide * canvas_height / float(canvas_width))

@onready var br_corner :Vector2i = Vector2i(target_tiles_wide - 1, target_tiles_wide - 1)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tiles.scale = float(canvas_width) / (target_tiles_wide * tile_size) * Vector2(1,1)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
