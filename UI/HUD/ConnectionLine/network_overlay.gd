extends Node2D

const GameColors = preload("res://Autoload/game_colors.gd")
const WIDTH_PX             := 1.5
const WIDTH_UNDERGROUND_PX := 4.0
const BRACKET_PAD    := 60.0
const BRACKET_CORNER := 20.0
const BRACKET_WIDTH  := 2.0

func _process(_delta: float) -> void:
	if SignalBus.connect_mode_enabled or SignalBus.disconnect_mode_enabled:
		SignalBus.hovered_network = null
	else:
		_update_line_hover()
	queue_redraw()

func _update_line_hover() -> void:
	var zoom        := get_viewport().get_canvas_transform().get_scale().x
	var threshold   := 8.0 / zoom
	var mouse_world := get_viewport().get_canvas_transform().affine_inverse() \
					   * get_viewport().get_mouse_position()
	var best_dist := INF
	var best_net  : Network = null
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
				best_net  = NetworkManager.get_network_for(clicker)
	SignalBus.hovered_network = best_net

func _draw() -> void:
	var zoom  := get_viewport().get_canvas_transform().get_scale().x
	var width := WIDTH_PX / zoom

	# Network outline brackets
	var outlined = SignalBus.outlined_network
	if outlined != null and NetworkManager.has_network(outlined):
		_draw_brackets(outlined, zoom)
	var hovered = SignalBus.hovered_network
	if hovered != null and hovered != outlined and NetworkManager.has_network(hovered):
		_draw_brackets(hovered, zoom)

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
			if clicker is Switch and (other as Clicker) is Switch:
				var uw := WIDTH_UNDERGROUND_PX / zoom
				_draw_dashed_line(clicker.global_position,
						(other as Clicker).global_position,
						GameColors.LINK_UNDERGROUND,
						uw, 8.0 / zoom, 6.0 / zoom)
			else:
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

func _draw_brackets(net: Network, zoom: float) -> void:
	if net.members.size() < 2:
		return
	var min_x := INF;  var min_y := INF
	var max_x := -INF; var max_y := -INF
	for m in net.members:
		var p := (m as Node2D).global_position
		min_x = minf(min_x, p.x); min_y = minf(min_y, p.y)
		max_x = maxf(max_x, p.x); max_y = maxf(max_y, p.y)
	var pad := BRACKET_PAD    / zoom
	var c   := BRACKET_CORNER / zoom
	var bw  := BRACKET_WIDTH  / zoom
	var tl  := Vector2(min_x - pad, min_y - pad)
	var br  := Vector2(max_x + pad, max_y + pad)
	var top_right := Vector2(br.x, tl.y)
	var bot_left  := Vector2(tl.x, br.y)
	var col := GameColors.link_color_for(net.get_pattern())
	col.a   = 0.9
	# Corner arms
	draw_line(tl,        tl        + Vector2( c,  0), col, bw, true)
	draw_line(tl,        tl        + Vector2( 0,  c), col, bw, true)
	draw_line(top_right, top_right + Vector2(-c,  0), col, bw, true)
	draw_line(top_right, top_right + Vector2( 0,  c), col, bw, true)
	draw_line(bot_left,  bot_left  + Vector2( c,  0), col, bw, true)
	draw_line(bot_left,  bot_left  + Vector2( 0, -c), col, bw, true)
	draw_line(br,        br        + Vector2(-c,  0), col, bw, true)
	draw_line(br,        br        + Vector2( 0, -c), col, bw, true)
	# Dotted sides — fixed screen-space density regardless of zoom
	var dash := 4.0  / zoom
	var gap  := 12.0 / zoom
	_draw_dashed_line(tl        + Vector2(c,  0), top_right + Vector2(-c,  0), col, bw, dash, gap)
	_draw_dashed_line(tl        + Vector2(0,  c), bot_left  + Vector2( 0, -c), col, bw, dash, gap)
	_draw_dashed_line(top_right + Vector2(0,  c), br        + Vector2( 0, -c), col, bw, dash, gap)
	_draw_dashed_line(bot_left  + Vector2(c,  0), br        + Vector2(-c,  0), col, bw, dash, gap)

func _draw_dashed_line(from: Vector2, to: Vector2, col: Color, width: float, dash: float, gap: float) -> void:
	var dir   := (to - from).normalized()
	var total := from.distance_to(to)
	var pos   := 0.0
	while pos < total:
		var a := from + dir * pos
		var b := from + dir * minf(pos + dash, total)
		draw_line(a, b, col, width, true)
		pos += dash + gap
