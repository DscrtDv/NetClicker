class_name FloatingWindow
extends Control

signal closed

@export var title : String = "WINDOW"

@onready var _title_label : Label  = $Window/Margin/VBox/TitleBar/TitleLabel
@onready var _close_btn   : Button = $Window/Margin/VBox/TitleBar/CloseBtn

func _ready() -> void:
	_title_label.text = title
	_close_btn.focus_mode = Control.FOCUS_NONE
	_close_btn.pressed.connect(close)
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
