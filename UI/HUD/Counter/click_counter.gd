class_name NetworkCounter
extends PanelContainer

@export var is_main : bool = true

@onready var counter_label        : Label   = $MarginContainer/VBoxContainer/HBoxContainer/CounterLabel
@onready var bps_container        : Control = $MarginContainer/VBoxContainer/BpsContainer
@onready var bps_label            : Label   = $MarginContainer/VBoxContainer/BpsContainer/BpsLabel
@onready var counts_container     : Control = $MarginContainer/VBoxContainer/CountsContainer
@onready var counts_inner         : Control = $MarginContainer/VBoxContainer/CountsContainer/CountsInner
@onready var node_count_label     : Label   = $MarginContainer/VBoxContainer/CountsContainer/CountsInner/NodeCountLabel
@onready var computer_count_label : Label   = $MarginContainer/VBoxContainer/CountsContainer/CountsInner/ComputerCountLabel
@onready var timer                : Timer   = $Timer

var total_bits     : int = 0
var bits_ps        : int = 0
var node_count     : int = 0
var computer_count : int = 0

var collapsed_h : float = 0.0
var expanded_h  : float = 0.0
var counts_h    : float = 0.0

var _pinned : bool       = false
var _style  : StyleBoxFlat

var _tracked_network = null  # Network

const BORDER_DEFAULT := Color(0.25, 0.25, 0.25, 0.90)
const BORDER_PINNED  := Color(1.00, 1.00, 1.00, 1.00)

func _ready() -> void:
	_style = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _style)

	if is_main:
		timer.wait_time = 1.0
		timer.start()
		update_counter()
		await get_tree().process_frame
		# BPS is always visible — measure bps container and pin it open
		var bps_h := bps_label.get_minimum_size().y
		bps_container.custom_minimum_size.y = bps_h
		# Counts slide in on hover — collapse to start
		counts_h = counts_inner.get_minimum_size().y
		counts_container.custom_minimum_size.y = 0.0
		counts_container.modulate.a = 0.0
		reset_size()
		await get_tree().process_frame
		collapsed_h = size.y
		expanded_h  = collapsed_h + counts_h + 3
	else:
		timer.stop()
		visible = false
		# For secondary counters, counts are always shown
		await get_tree().process_frame
		var bps_h := bps_label.get_minimum_size().y
		bps_container.custom_minimum_size.y = bps_h
		counts_container.custom_minimum_size.y = counts_inner.get_minimum_size().y
		SignalBus.tooltip_show.connect(_on_tooltip_show)
		SignalBus.tooltip_hide.connect(_on_tooltip_hide)
		SignalBus.network_tick.connect(_on_network_tick)

func format_bits(n: int) -> String:
	var s      := "%06d" % n
	var result := ""
	for i in range(s.length() - 1, -1, -1):
		var pos := s.length() - 1 - i
		if pos > 0 and pos % 3 == 0:
			result = " " + result
		result = s[i] + result
	return result

func update_counter() -> void:
	counter_label.text    = format_bits(total_bits)
	bps_label.text        = "%s bps" % format_bits(bits_ps)
	node_count_label.text = "Node Count: %d" % node_count
	var at_cap := computer_count >= SignalBus.max_network_size
	computer_count_label.text     = "Computers: %d / %d" % [computer_count, SignalBus.max_network_size]
	computer_count_label.modulate = Color(1.0, 0.4, 0.4, 1) if at_cap else Color(0.55, 0.55, 0.65, 1)
	if is_main:
		SignalBus.total_bits = total_bits
		SignalBus.bits_changed.emit(total_bits)

func _expand() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(counts_container, "custom_minimum_size:y", counts_h, 0.15)
	tw.tween_property(self, "size:y", expanded_h, 0.15)
	tw.tween_property(counts_container, "modulate:a", 1.0, 0.15)

func _collapse() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(counts_container, "custom_minimum_size:y", 0.0, 0.15)
	tw.tween_property(self, "size:y", collapsed_h, 0.15)
	tw.tween_property(counts_container, "modulate:a", 0.0, 0.15)

func _set_border(color: Color) -> void:
	create_tween().tween_property(_style, "border_color", color, 0.15)

func _gui_input(event: InputEvent) -> void:
	if not is_main:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pinned = not _pinned
		_set_border(BORDER_PINNED if _pinned else BORDER_DEFAULT)
		if not _pinned:
			SignalBus.outlined_network = null
		get_viewport().set_input_as_handled()

func _on_timer_timeout() -> void:
	var delta  : int = NetworkManager.tick()
	var main         = NetworkManager.get_main()
	total_bits += delta
	bits_ps        = main.get_bps()            if main != null else 0
	node_count     = main.get_size()           if main != null else 0
	computer_count = main.get_computer_count() if main != null else 0
	update_counter()
	SignalBus.network_tick.emit()

func _on_mouse_entered() -> void:
	if is_main:
		_expand()
		SignalBus.outlined_network = NetworkManager.get_main()

func _on_mouse_exited() -> void:
	if is_main:
		if not _pinned:
			_collapse()
			SignalBus.outlined_network = null

# --- Secondary counter ---

func _on_tooltip_show(_node_name: String, _network: String, _state: bool, _bit_ps: int, anchor: Node2D) -> void:
	var net = NetworkManager.get_network_for(anchor)
	if net == null or net.is_main:
		visible = false
		_tracked_network = null
		return
	_tracked_network = net
	_refresh_from_network()
	visible = true

func _on_tooltip_hide() -> void:
	_tracked_network = null
	visible = false

func _on_network_tick() -> void:
	if _tracked_network != null:
		_refresh_from_network()

func _refresh_from_network() -> void:
	total_bits     = int(_tracked_network.banked_bits)
	bits_ps        = _tracked_network.get_bps()
	node_count     = _tracked_network.get_size()
	computer_count = _tracked_network.get_computer_count()
	update_counter()
