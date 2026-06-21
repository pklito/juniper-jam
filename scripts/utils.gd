class_name Utils
enum TileType{
	NONE,
	GROUND
}

const DIRS := [
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.RIGHT
]

static func rotate_clockwise(vec: Vector2i) -> Vector2i:
	return Vector2i(vec.y, -vec.x)

static func rotate_counterclockwise(vec: Vector2i) -> Vector2i:
	return Vector2i(-vec.y, vec.x)

static func dir_to_vec2(dir: int) -> Vector2i:
	return DIRS[posmod(dir, 4)]

static func vec2_to_dir(vec: Vector2i) -> int:
	# Not optimized but wont error for any vector so i'm chilling
	assert(vec.x == 0 or vec.y == 0, "vec2_to_dir was given a non-cardinal vector: (%d,%d)" % [vec.x, vec.y])
	var max := 0
	var max_dir := 0
	for i in range(4):
		var dir = DIRS[i]
		var dot_prod = dir.x * vec.x + dir.y*vec.y
		if dot_prod > max:
			max = dot_prod
			max_dir = i
	return max_dir
