extends Node2D

const GameColors = preload("res://Autoload/game_colors.gd")
const WIDTH_PX   := 1.5

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var zoom  := get_viewport().get_canvas_transform().get_scale().x
	var width := WIDTH_PX / zoom

	# Draw permanent connections — each pair once
	var drawn : Dictionary = {}
	for node in get_tree().get_nodes_in_group("Clickers"):
		var clicker := node as Clicker
		for other in clicker.connections:
			var id_a := clicker.get_instance_id()
			var id_b := (other as Clicker).get_instance_id()
			var key  := "%d_%d" % [mini(id_a, id_b), maxi(id_a, id_b)]
			if drawn.has(key):
				continue
			drawn[key] = true
			var net     = NetworkManager.get_network_for(clicker)
			var pattern := net.get_pattern() if net != null else "none"
			var col     : Color = GameColors.link_color_for(pattern)
			draw_line(clicker.global_position,
					  (other as Clicker).global_position,
					  col, width, true)

	# Preview line from selected source to mouse (world space)
	if not SignalBus.connect_mode_enabled or SignalBus.connection_source == null:
		return
	var src         := SignalBus.connection_source as Clicker
	var mouse_world := get_viewport().get_canvas_transform().affine_inverse() \
					   * get_viewport().get_mouse_position()
	draw_line(src.global_position, mouse_world, GameColors.LINK_PREVIEW, width, true)

func _unhandled_input(event: InputEvent) -> void:
	if not SignalBus.disconnect_mode_enabled:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var zoom        := get_viewport().get_canvas_transform().get_scale().x
	var threshold   := 8.0 / zoom
	var mouse_world := get_viewport().get_canvas_transform().affine_inverse() \
					   * get_viewport().get_mouse_position()

	var best_dist := INF
	var best_a    : Clicker = null
	var best_b    : Clicker = null
	var checked   : Dictionary = {}

	for node in get_tree().get_nodes_in_group("Clickers"):
		var clicker := node as Clicker
		for other in clicker.connections:
			var id_a := clicker.get_instance_id()
			var id_b := (other as Clicker).get_instance_id()
			var key  := "%d_%d" % [mini(id_a, id_b), maxi(id_a, id_b)]
			if checked.has(key):
				continue
			checked[key] = true
			var dist := _point_to_seg(mouse_world, clicker.global_position, (other as Clicker).global_position)
			if dist < threshold and dist < best_dist:
				best_dist = dist
				best_a    = clicker
				best_b    = other as Clicker

	if best_a == null:
		return
	if SignalBus.connection_source != null:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
	best_a.disconnect_from(best_b)
	NetworkManager.rebuild()
	SignalBus.connection_formed.emit(best_a, best_b)
	get_viewport().set_input_as_handled()

func _point_to_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 0.001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _has_any_connections() -> bool:
	for node in get_tree().get_nodes_in_group("Clickers"):
		if (node as Clicker).connections.size() > 0:
			return true
	return false
