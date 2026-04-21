extends Node2D

const COLOR_ON      := Color(0.192, 0.718, 0.643, 1.00)
const COLOR_OFF     := Color(0.85,  0.85,  0.90,  0.50)
const TIP_LENGTH    := 14.0
const HALF_BASE     := 9.0
const HOVER_OFFSET  := 60.0
const EDGE_MARGIN   := 28.0
const BOB_SPEED     := 2.5
const BOB_AMPLITUDE := 4.0

var _computer : Node2D = null
var _bob_time : float  = 0.0

var _color : Color = COLOR_OFF :
	set(v):
		_color = v
		queue_redraw()

func _ready() -> void:
	visible = false
	SignalBus.clicker_spawned.connect(_on_clicker_spawned)
	SignalBus.pointer_toggled.connect(func(enabled: bool) -> void:
		visible = enabled and _computer != null
	)
	for node in get_tree().get_nodes_in_group("Clickers"):
		if node is Computer:
			_on_clicker_spawned(node)
			break

func _on_clicker_spawned(node: Node) -> void:
	if not (node is Computer) or _computer != null:
		return
	_computer = node
	_color    = COLOR_ON if node.powered else COLOR_OFF
	visible   = SignalBus.pointer_enabled
	node.computer_on.connect(func(_b: int):  _transition_color(COLOR_ON))
	node.computer_off.connect(func(_b: int): _transition_color(COLOR_OFF))
	visible = true

func _transition_color(c: Color) -> void:
	create_tween().tween_property(self, "_color", c, 0.25)

func _process(delta: float) -> void:
	if not _computer:
		return
	_bob_time += delta

	var vp_size    := get_viewport_rect().size
	var screen_pos := get_viewport().get_canvas_transform() * _computer.global_position
	var safe_rect  := Rect2(
		Vector2(EDGE_MARGIN, EDGE_MARGIN),
		vp_size - Vector2(EDGE_MARGIN * 2.0, EDGE_MARGIN * 2.0)
	)

	if safe_rect.has_point(screen_pos):
		var bob := sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE
		position = screen_pos + Vector2(0.0, -HOVER_OFFSET + bob)
		rotation  = PI * 0.5
	else:
		var clamped := Vector2(
			clamp(screen_pos.x, safe_rect.position.x, safe_rect.end.x),
			clamp(screen_pos.y, safe_rect.position.y, safe_rect.end.y)
		)
		position = clamped
		rotation  = (screen_pos - clamped).angle()

	queue_redraw()

func _draw() -> void:
	var tip := Vector2( TIP_LENGTH,          0.0)
	var bl  := Vector2(-TIP_LENGTH * 0.4,  HALF_BASE)
	var br  := Vector2(-TIP_LENGTH * 0.4, -HALF_BASE)
	draw_colored_polygon([tip, bl, br], _color)
