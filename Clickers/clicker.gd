extends LODObject
class_name Clicker

const GameColors := preload("res://Autoload/game_colors.gd")

@onready var power_indicator: ColorRect = $DetailView/PowerIndicator
@onready var proxy: Polygon2D = $ProxyView/Polygon2D
@onready var bracket: Node2D = $SelectionBracket
@onready var sprite: Sprite2D = $DetailView/Sprite2D

signal bits_updated(bit_ps: int)

@export var clicker_type: String = "Clicker"
@export var bit_ps: int = 1
@export var base_price: int = 0
@export var price_scale: float = 1.15
@export var is_origin: bool = false
@export var max_connections: int = 2

var connections: Array[Clicker] = []
var mouse_over := false
var grabbing := false
var powered := false
var network_name := "Main Network"

var hover_modulate := Color(1.3, 1.3, 1.3)
var normal_modulate := Color(1.0, 1.0, 1.0)

const TINT_SOURCE := Color(0.30, 1.10, 0.95)
const TINT_VALID := Color(0.40, 1.10, 0.50)
const TINT_INVALID := Color(1.10, 0.40, 0.40)


func _ready() -> void:
	super._ready()
	add_to_group("Clickers")
	init_prices()
	load_sprite()

	power_indicator.modulate = GameColors.SCREEN_OFF
	proxy.color = Color.WHITE
	bracket.visible = false

	SignalBus.clicker_spawned.emit(self)
	SignalBus.connection_source_selected.connect(_on_connection_source_selected)
	SignalBus.connection_cancelled.connect(_on_connection_cleared)
	SignalBus.connection_formed.connect(_on_connection_formed)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click") and mouse_over:
		if SignalBus.connect_mode_enabled:
			handle_connect_click()
			get_viewport().set_input_as_handled()
			return

		if SignalBus.disconnect_mode_enabled:
			handle_disconnect_click()
			get_viewport().set_input_as_handled()
			return

	if Input.is_action_just_pressed("left_click") and (mouse_over or grabbing):
		if not grabbing:
			if SignalBus.entity_grabbed != null:
				return

			grabbing = true
			SignalBus.entity_grabbed = self
			bracket.on_grab()
			SignalBus.tooltip_hide.emit()

		var snapped_pos := SignalBus.snap_to_grid(get_global_mouse_position())
		if not _is_grid_slot_blocked(snapped_pos):
			global_position = snapped_pos

	if Input.is_action_just_released("left_click"):
		if grabbing:
			grabbing = false
			SignalBus.entity_grabbed = null

			var snapped_pos := SignalBus.snap_to_grid(get_global_mouse_position())
			if not _is_grid_slot_blocked(snapped_pos):
				global_position = snapped_pos

			mouse_over = global_position.distance_to(get_global_mouse_position())
			bracket.on_release(mouse_over)

			if mouse_over:
				SignalBus.tooltip_show.emit(clicker_type, network_name, powered, get_bit_ps(), self)
			else:
				SignalBus.tooltip_hide.emit()

	if Input.is_action_just_pressed("right_click") and mouse_over:
		if SignalBus.connect_mode_enabled or SignalBus.disconnect_mode_enabled:
			return

		powered = not powered
		if powered:
			var color := get_pattern_color()
			power_indicator.modulate = color
			proxy.color = color
		else:
			power_indicator.modulate = GameColors.SCREEN_OFF
			proxy.color = Color.WHITE

		on_power_changed(powered)
		SignalBus.tooltip_show.emit(clicker_type, network_name, powered, get_bit_ps(), self)


func _is_grid_slot_blocked(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("Clickers"):
		if node == self:
			continue
		if node.global_position == pos:
			return true
	return false

# --- Virtuals ---

func init_prices() -> void:
	pass


func on_power_changed(on: bool) -> void:
	pass


func blocks_traversal() -> bool:
	return false

# --- Stats ---

func get_bit_ps() -> int:
	return bit_ps

# --- Connections ---

func connect_to(other: Clicker) -> void:
	if other not in connections:
		connections.append(other)
	if self not in other.connections:
		other.connections.append(self)


func disconnect_from(other: Clicker) -> void:
	connections.erase(other)
	other.connections.erase(self)


func handle_connect_click() -> void:
	var src := SignalBus.connection_source

	if src == null:
		if connections.size() >= max_connections:
			return
		SignalBus.connection_source = self
		SignalBus.connection_source_selected.emit(self)
		return

	if src == self:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
		return

	if not can_connect_to(src as Clicker):
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()
		return

	(src as Clicker).connect_to(self)
	NetworkManager.rebuild()
	SignalBus.connection_source = null
	SignalBus.connection_formed.emit(src, self)


func handle_disconnect_click() -> void:
	var src := SignalBus.connection_source

	if src == null:
		if connections.is_empty():
			return
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


func can_connect_to(src: Clicker) -> bool:
	if connections.size() >= max_connections:
		return false
	if src in connections:
		return false

	var net_self = NetworkManager.get_network_for(self)
	var net_src = NetworkManager.get_network_for(src)

	if net_self == null or net_src == null or net_self == net_src:
		return true

	if net_self.is_main or net_src.is_main:
		var other: Network = net_src if net_self.is_main else net_self
		var main := NetworkManager.get_main()
		if main != null and main.get_computer_count() + other.get_computer_count() > SignalBus.max_network_size:
			return false

	return true

# --- Power indicator ---

func get_pattern_color() -> Color:
	var net = NetworkManager.get_network_for(self)
	var pattern = net.get_pattern() if net != null else "none"
	return GameColors.screen_on_for(pattern)


func refresh_power_indicator() -> void:
	if not powered:
		return
	var color := get_pattern_color()
	power_indicator.modulate = color
	proxy.color = color

# --- Visual feedback ---

func _on_mouse_entered() -> void:
	mouse_over = true
	if not grabbing:
		bracket.on_hover()

	var tint := hover_modulate

	if SignalBus.connect_mode_enabled:
		var src := SignalBus.connection_source
		if src == self:
			tint = TINT_SOURCE
		elif src != null:
			tint = TINT_VALID if can_connect_to(src as Clicker) else TINT_INVALID
	elif SignalBus.disconnect_mode_enabled:
		var src := SignalBus.connection_source
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
	if SignalBus.connect_mode_enabled and SignalBus.connection_source == self:
		tint = TINT_SOURCE

	create_tween().tween_property(self, "modulate", tint, 0.15)
	SignalBus.tooltip_hide.emit()


func _on_connection_source_selected(src: Node) -> void:
	if src == self:
		create_tween().tween_property(self, "modulate", TINT_SOURCE, 0.15)


func _on_connection_formed(_a = null, _b = null) -> void:
	_on_connection_cleared()
	refresh_power_indicator()


func _on_connection_cleared(_a = null, _b = null) -> void:
	if not mouse_over:
		create_tween().tween_property(self, "modulate", normal_modulate, 0.15)

# --- Sprite auto-load ---

func load_sprite() -> void:
	var script_path: String = get_script().resource_path
	var dir: String = script_path.get_base_dir()
	var script_name: String = script_path.get_file().get_basename()
	var path: String = dir.path_join("%s.png" % script_name)

	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("Clicker: no sprite found at %s" % path)
