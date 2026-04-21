extends Clicker
class_name Computer

const GameColors = preload("res://Autoload/game_colors.gd")

@onready var screen     := $DetailView/Screen
@onready var proxy      := $ProxyView/Polygon2D
@onready var bracket    := $SelectionBracket

signal computer_on(bit_ps : int)
signal computer_off(bit_ps : int)

var mouse_over          := false
var grabbing            := false
var powered             := false
var mousePos : Vector2  = Vector2.ZERO
var deltaPos : Vector2  = Vector2.ZERO

var screen_off_color : Color = Color(0.2, 0.2, 0.2)

var network_name    := "Main Network"
var hover_modulate  := Color(1.3, 1.3, 1.3)
var normal_modulate := Color(1.0, 1.0, 1.0)

const TINT_SOURCE  := Color(0.30, 1.10, 0.95)
const TINT_VALID   := Color(0.40, 1.10, 0.50)
const TINT_INVALID := Color(1.10, 0.40, 0.40)

var _grab_origin : Vector2 = Vector2.ZERO

func init_prices() -> void:
	base_price  = 0
	price_scale = 1.50

func _ready() -> void:
	super._ready()
	init_prices()
	screen.modulate = screen_off_color
	proxy.color     = Color.WHITE
	bracket.visible = false
	clicker_type    = "Computer"
	min_separation  = 32.0
	SignalBus.clicker_spawned.emit(self)
	SignalBus.connection_source_selected.connect(_on_connection_source_selected)
	SignalBus.connection_cancelled.connect(_on_connection_cleared)
	SignalBus.connection_formed.connect(_on_connection_cleared)

func _process(_delta: float) -> void:
	deltaPos = mousePos - get_global_mouse_position()
	mousePos = get_global_mouse_position()

func _input(_event: InputEvent) -> void:
	# Connect / disconnect mode intercepts left click
	if Input.is_action_just_pressed("left_click") and mouse_over:
		if SignalBus.connect_mode_enabled:
			_handle_connect_click()
			get_viewport().set_input_as_handled()
			return
		if SignalBus.disconnect_mode_enabled:
			_handle_disconnect_click()
			get_viewport().set_input_as_handled()
			return

	# Grab
	if Input.is_action_just_pressed("left_click") and mouse_over or grabbing:
		if not grabbing:
			if SignalBus.entity_grabbed != null:
				return
			grabbing = true
			_grab_origin = global_position
			SignalBus.entity_grabbed = self
			bracket.on_grab()
			SignalBus.tooltip_hide.emit()
		global_position -= deltaPos

	if Input.is_action_just_released("left_click"):
		if grabbing:
			grabbing = false
			SignalBus.entity_grabbed = null
			global_position = _find_safe_position(global_position)
			mouse_over = global_position.distance_to(get_global_mouse_position()) < min_separation * 0.5
			bracket.on_release(mouse_over)
			if mouse_over:
				SignalBus.tooltip_show.emit(clicker_type, network_name, powered, get_bit_ps(), self)
			else:
				SignalBus.tooltip_hide.emit()

	if Input.is_action_just_pressed("right_click") and mouse_over:
		# In connect mode, right-click cancels source selection
		if SignalBus.connect_mode_enabled and SignalBus.connection_source != null:
			SignalBus.connection_source = null
			SignalBus.connection_cancelled.emit()
			return
		powered = not powered
		if powered:
			var on_col := _get_pattern_color()
			screen.modulate = on_col
			proxy.color     = on_col
			computer_on.emit(get_bit_ps())
		else:
			screen.modulate = screen_off_color
			proxy.color     = Color.WHITE
			computer_off.emit(get_bit_ps())
		SignalBus.tooltip_show.emit(clicker_type, network_name, powered, get_bit_ps(), self)

# --- Connect mode ---

func _handle_connect_click() -> void:
	var src = SignalBus.connection_source
	if src == null:
		if connections.size() < max_connections:
			SignalBus.connection_source = self
			SignalBus.connection_source_selected.emit(self)
		return
	if src == self:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
		return
	if not _can_connect_to(src as Clicker):
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
		return
	(src as Clicker).connect_to(self)
	NetworkManager.rebuild()
	SignalBus.connection_source = null
	SignalBus.connection_formed.emit(src, self)

func _handle_disconnect_click() -> void:
	var src = SignalBus.connection_source
	if src == null:
		if connections.size() > 0:
			SignalBus.connection_source = self
			SignalBus.connection_source_selected.emit(self)
		return
	if src == self:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
		return
	if self not in (src as Clicker).connections:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
		return
	(src as Clicker).disconnect_from(self)
	NetworkManager.rebuild()
	SignalBus.connection_source = null
	SignalBus.connection_formed.emit(src, self)

func _can_connect_to(src: Clicker) -> bool:
	if connections.size() >= max_connections:
		return false
	if src in connections:
		return false
	var net_self = NetworkManager.get_network_for(self)
	var net_src  = NetworkManager.get_network_for(src)
	if net_self == null or net_src == null or net_self == net_src:
		return true
	if net_self.is_main or net_src.is_main:
		var other : Network = net_src if net_self.is_main else net_self
		var main  : Network = NetworkManager.get_main()
		if main != null and main.get_size() + other.get_size() > SignalBus.max_network_size:
			return false
	return true

# --- Screen color ---

func _get_pattern_color() -> Color:
	var net = NetworkManager.get_network_for(self)
	var pattern := net.get_pattern() if net != null else "none"
	return GameColors.screen_on_for(pattern)

func _refresh_screen_color() -> void:
	if not powered:
		return
	var col := _get_pattern_color()
	screen.modulate = col
	proxy.color     = col

# --- Visual feedback ---

func _on_mouse_entered() -> void:
	mouse_over = true
	if not grabbing:
		bracket.on_hover()
	var tint := hover_modulate
	if SignalBus.connect_mode_enabled:
		var src = SignalBus.connection_source
		if src == self:
			tint = TINT_SOURCE
		elif src != null:
			tint = TINT_VALID if _can_connect_to(src as Clicker) else TINT_INVALID
	elif SignalBus.disconnect_mode_enabled:
		var src = SignalBus.connection_source
		if src == self:
			tint = TINT_SOURCE
		elif src != null:
			tint = TINT_INVALID if self in (src as Clicker).connections else hover_modulate
	create_tween().tween_property(self, "modulate", tint, 0.15)
	SignalBus.tooltip_show.emit(clicker_type, network_name, powered, get_bit_ps(), self)

func _on_mouse_exited() -> void:
	if not grabbing:
		mouse_over = false
		bracket.on_exit()
		var tint := normal_modulate
		# Stay tinted if we are the active source
		if SignalBus.connect_mode_enabled and SignalBus.connection_source == self:
			tint = TINT_SOURCE
		create_tween().tween_property(self, "modulate", tint, 0.15)
		SignalBus.tooltip_hide.emit()

func _on_connection_source_selected(src: Node) -> void:
	if src == self:
		create_tween().tween_property(self, "modulate", TINT_SOURCE, 0.15)

func _on_connection_cleared(_a = null, _b = null) -> void:
	if not mouse_over:
		create_tween().tween_property(self, "modulate", normal_modulate, 0.15)

# --- Placement ---

func _find_safe_position(desired: Vector2) -> Vector2:
	var pos := desired
	for _i in range(8):
		var blocker : Node2D = null
		var closest := INF
		for node in get_tree().get_nodes_in_group("Clickers"):
			if node == self:
				continue
			var d := pos.distance_to(node.global_position)
			if d < min_separation and d < closest:
				closest = d
				blocker = node
		if blocker == null:
			return pos
		var dir := (pos - blocker.global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		pos = blocker.global_position + dir * min_separation
	return pos
