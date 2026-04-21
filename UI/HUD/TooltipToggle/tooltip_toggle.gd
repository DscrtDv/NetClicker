extends PanelContainer

@onready var state_label : Label = $MarginContainer/HBoxContainer/StateLabel

var hover_modulate  := Color(1.20, 1.20, 1.20)
var normal_modulate := Color(1.00, 1.00, 1.00)
var _style          : StyleBoxFlat

func _ready() -> void:
	_style = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _style)
	SignalBus.tooltip_toggled.connect(func(_e: bool) -> void: _update_label())
	_update_label()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SignalBus.tooltip_enabled = not SignalBus.tooltip_enabled
		SignalBus.tooltip_toggled.emit(SignalBus.tooltip_enabled)
		get_viewport().set_input_as_handled()

func _on_mouse_entered() -> void:
	create_tween().tween_property(self, "modulate", hover_modulate, 0.10)

func _on_mouse_exited() -> void:
	create_tween().tween_property(self, "modulate", normal_modulate, 0.10)

func _update_label() -> void:
	if SignalBus.tooltip_enabled:
		state_label.modulate = Color(0.20, 0.85, 0.60)
		_style.border_color   = Color(0.20, 0.85, 0.60, 0.90)
	else:
		state_label.modulate = Color(0.85, 0.35, 0.30)
		_style.border_color   = Color(0.85, 0.35, 0.30, 0.90)
