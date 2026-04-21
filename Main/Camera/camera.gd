extends Camera2D

const ZOOM_STEP := 0.05
const ZOOM_MIN := Vector2(0.5, 0.5)
const ZOOM_MAX := Vector2(4.0, 4.0)
const LOD_THRESHOLD := 1.2

var _dragging := false


func _ready() -> void:
	zoom = ZOOM_MAX
	_emit_lod_if_changed(zoom.x)

func _emit_lod_if_changed(zoom_x: float) -> void:
	var level := 0 if zoom_x >= LOD_THRESHOLD else 1
	if level != SignalBus.current_lod:
		SignalBus.current_lod = level
		SignalBus.lod_changed.emit(level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("middle_click"):
		_dragging = true

	if event.is_action_released("middle_click"):
		_dragging = false

	if event is InputEventMouseMotion and _dragging:
		global_position -= event.relative / zoom

	if event is InputEventMouseButton:
		var direction := 0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			direction = 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			direction = -1

		if direction != 0:
			var mouse_viewport := get_viewport().get_mouse_position() - get_viewport_rect().size / 2.0
			var old_zoom := zoom
			zoom = clamp(zoom + Vector2(ZOOM_STEP, ZOOM_STEP) * direction, ZOOM_MIN, ZOOM_MAX)
			global_position += mouse_viewport / old_zoom - mouse_viewport / zoom
			_emit_lod_if_changed(zoom.x)
