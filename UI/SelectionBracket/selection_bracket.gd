extends Node2D

@export var hover_size := Vector2(26, 26)
@export var grab_size  := Vector2(20, 20)
@export var corner_len := 5.0
@export var thickness  := 1.5
@export var color      := Color.WHITE

var size := Vector2(20, 20):
	set(v):
		size = v
		queue_redraw()


func on_hover() -> void:
	visible = true
	create_tween().tween_property(self, "size", hover_size, 0.1)

func on_grab() -> void:
	create_tween().tween_property(self, "size", grab_size, 0.08)

func on_release(is_hovering: bool) -> void:
	if is_hovering:
		create_tween().tween_property(self, "size", hover_size, 0.1)
	else:
		visible = false

func on_exit() -> void:
	visible = false


func _draw() -> void:
	var h := size / 2
	var c := corner_len
	var corners := [
		[-h.x, -h.y, Vector2.RIGHT, Vector2.DOWN],
		[ h.x, -h.y, Vector2.LEFT,  Vector2.DOWN],
		[-h.x,  h.y, Vector2.RIGHT, Vector2.UP  ],
		[ h.x,  h.y, Vector2.LEFT,  Vector2.UP  ],
	]
	for corner in corners:
		var p := Vector2(corner[0], corner[1])
		draw_line(p, p + corner[2] * c, color, thickness)
		draw_line(p, p + corner[3] * c, color, thickness)
