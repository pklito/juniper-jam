extends Node2D

signal dragged_successfully(drag_vector : Vector2)

enum CurrentState {
	IDLE,
	DRAGGING,
	DRAGGING_OUT
}

var state : CurrentState = CurrentState.IDLE
var click_pos : Vector2 = Vector2.ZERO
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			assert(state == CurrentState.IDLE)
			click_pos = event.position
			state = CurrentState.DRAGGING


func _on_area_2d_mouse_entered() -> void:
	if state == CurrentState.IDLE:
		return
	assert(state == CurrentState.DRAGGING_OUT)
	state = CurrentState.DRAGGING

func _on_area_2d_mouse_exited() -> void:
	if state == CurrentState.IDLE:
		return
	assert(state == CurrentState.DRAGGING)
	state = CurrentState.DRAGGING_OUT

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or event.pressed:
		return
	if state == CurrentState.IDLE:
		return
	# Left mouse button was released
	if state == CurrentState.DRAGGING_OUT:
		dragged_successfully.emit(event.position - click_pos)
	state = CurrentState.IDLE
	
