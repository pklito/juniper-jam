extends Node

var ALLOW_CORNER_TURN = true

enum MoveRules {
    FREE_MOVEMENT,
    FREE_COPY_MOVEMENT,
    FREE_COPY_MOVEMENT_INVERSE,
    ALTERNATING,
    SQUARE_ONLY
}

enum ClimbRules {
    FLOAT,
    FALL_DOWN,
    LOCK
}

var CLIMB_RULE = ClimbRules.FLOAT
var MOVE_RULE = MoveRules.FREE_MOVEMENT