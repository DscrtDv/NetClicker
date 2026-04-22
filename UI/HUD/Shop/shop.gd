extends Control

const SIDEBAR_W      := 220.0
const TAB_W          := 36.0
const SLIDE_DURATION := 0.25

const BORDER_OPEN    := Color(0.192, 0.718, 0.643, 0.90)
const BORDER_CLOSED  := Color(0.250, 0.250, 0.250, 0.90)

var _open := false

@onready var _tab               : PanelContainer = $Tab
@onready var _sidebar           : PanelContainer = $Sidebar

var _style_tab     : StyleBoxFlat
var _style_sidebar : StyleBoxFlat

func _ready() -> void:
	_style_tab     = _tab.get_theme_stylebox("panel").duplicate()
	_style_sidebar = _sidebar.get_theme_stylebox("panel").duplicate()
	_tab.add_theme_stylebox_override("panel", _style_tab)
	_sidebar.add_theme_stylebox_override("panel", _style_sidebar)
	offset_left = -TAB_W

func _toggle() -> void:
	_open = not _open
	var target       := -(TAB_W + SIDEBAR_W) if _open else -TAB_W
	var border_color := BORDER_OPEN if _open else BORDER_CLOSED
	create_tween() \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUINT) \
		.tween_property(self, "offset_left", target, SLIDE_DURATION)
	var t := create_tween()
	t.tween_property(_style_tab,     "border_color", border_color, SLIDE_DURATION)
	t.parallel().tween_property(_style_sidebar, "border_color", border_color, SLIDE_DURATION)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE and _open:
		_toggle()
		get_viewport().set_input_as_handled()

func _on_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle()
		get_viewport().set_input_as_handled()

func _on_tab_mouse_entered() -> void:
	create_tween().tween_property(_tab, "modulate", Color(1.2, 1.2, 1.2), 0.10)

func _on_tab_mouse_exited() -> void:
	create_tween().tween_property(_tab, "modulate", Color(1.0, 1.0, 1.0), 0.10)
