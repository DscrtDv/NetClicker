class_name HudToggle
extends PanelContainer

signal toggled(enabled: bool)

@export var label_text    : String = "BTN"
@export var initial_state : bool   = true

@onready var key_label   : Label = $MarginContainer/HBoxContainer/KeyLabel
@onready var state_label : Label = $MarginContainer/HBoxContainer/StateLabel

const BORDER_ON  := Color(0.20, 0.85, 0.60, 0.90)
const BORDER_OFF := Color(0.85, 0.35, 0.30, 0.90)
const DOT_ON     := Color(0.20, 0.85, 0.60)
const DOT_OFF    := Color(0.85, 0.35, 0.30)

var _enabled : bool
var _style   : StyleBoxFlat

var hover_modulate  := Color(1.20, 1.20, 1.20)
var normal_modulate := Color(1.00, 1.00, 1.00)

func _ready() -> void:
	_style = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _style)
	_enabled     = initial_state
	key_label.text = label_text
	_update_visuals()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_enabled = not _enabled
		_update_visuals()
		toggled.emit(_enabled)
		get_viewport().set_input_as_handled()

func _on_mouse_entered() -> void:
	create_tween().tween_property(self, "modulate", hover_modulate, 0.10)

func _on_mouse_exited() -> void:
	create_tween().tween_property(self, "modulate", normal_modulate, 0.10)

func public_toggle() -> void:
	_enabled = not _enabled
	_update_visuals()
	toggled.emit(_enabled)

func set_state_silent(state: bool) -> void:
	_enabled = state
	_update_visuals()

func _update_visuals() -> void:
	state_label.modulate = DOT_ON  if _enabled else DOT_OFF
	_style.border_color  = BORDER_ON if _enabled else BORDER_OFF
