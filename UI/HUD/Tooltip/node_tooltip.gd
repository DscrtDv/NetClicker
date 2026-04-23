extends PanelContainer

@onready var header_label  : Label = $MarginContainer/VBoxContainer/HeaderLabel
@onready var network_value : Label = $MarginContainer/VBoxContainer/Grid/NetworkValue
@onready var state_value   : Label = $MarginContainer/VBoxContainer/Grid/StateValue
@onready var bits_key      : Label = $MarginContainer/VBoxContainer/Grid/BitsKey
@onready var bits_value    : Label = $MarginContainer/VBoxContainer/Grid/BitsValue

var _anchor : Node2D = null

func _ready() -> void:
	visible = false
	SignalBus.tooltip_show.connect(_on_tooltip_show)
	SignalBus.tooltip_hide.connect(_on_tooltip_hide)
	SignalBus.tooltip_toggled.connect(func(enabled: bool) -> void:
		if not enabled:
			_on_tooltip_hide()
	)

func _process(_delta: float) -> void:
	if _anchor and visible:
		_update_position()

func _on_tooltip_show(node_name: String, network: String, state: bool, bit_ps: int, anchor: Node2D) -> void:
	if not SignalBus.tooltip_enabled:
		return
	header_label.text = node_name.to_upper()
	network_value.text = network
	state_value.text = "ON" if state else "OFF"
	state_value.modulate = Color(0.20, 0.85, 0.60) if state else Color(0.85, 0.35, 0.30)
	var show_bps := bit_ps > 0
	bits_key.visible   = show_bps
	bits_value.visible = show_bps
	if show_bps:
		bits_value.text = _format_bits(bit_ps)
	_anchor = anchor
	visible = true

func _on_tooltip_hide() -> void:
	visible = false
	_anchor = null

func _update_position() -> void:
	var screen_pos := _anchor.get_viewport().get_canvas_transform() * _anchor.global_position
	var offset     := Vector2(60.0, -size.y * 0.5)
	position = screen_pos + offset
	var vp := get_viewport_rect().size
	position.x = clamp(position.x, 4.0, vp.x - size.x - 4.0)
	position.y = clamp(position.y, 4.0, vp.y - size.y - 4.0)

func _format_bits(n: int) -> String:
	var s      := "%06d" % n
	var result := ""
	for i in range(s.length() - 1, -1, -1):
		var pos := s.length() - 1 - i
		if pos > 0 and pos % 3 == 0:
			result = " " + result
		result = s[i] + result
	return result
