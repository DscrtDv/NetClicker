extends Control

const SIDEBAR_W      := 220.0
const TAB_W          := 36.0
const SLIDE_DURATION := 0.25

const BORDER_OPEN    := Color(0.192, 0.718, 0.643, 0.90)
const BORDER_CLOSED  := Color(0.250, 0.250, 0.250, 0.90)

var _open := false

@onready var _tab               : PanelContainer = $Tab
@onready var _sidebar           : PanelContainer = $Sidebar
@onready var _connect_toggle    : HudToggle      = $ConnectToggle
@onready var _disconnect_toggle : HudToggle      = $DisconnectToggle

var _style_tab     : StyleBoxFlat
var _style_sidebar : StyleBoxFlat

func _ready() -> void:
	_style_tab     = _tab.get_theme_stylebox("panel").duplicate()
	_style_sidebar = _sidebar.get_theme_stylebox("panel").duplicate()
	_tab.add_theme_stylebox_override("panel", _style_tab)
	_sidebar.add_theme_stylebox_override("panel", _style_sidebar)
	offset_left = -TAB_W
	_connect_toggle.toggled.connect(_on_connect_toggled)
	_disconnect_toggle.toggled.connect(_on_disconnect_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				_connect_toggle.public_toggle()
				get_viewport().set_input_as_handled()
			KEY_X:
				_disconnect_toggle.public_toggle()
				get_viewport().set_input_as_handled()

func _clear_source() -> void:
	if SignalBus.connection_source != null:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()

func _on_connect_toggled(enabled: bool) -> void:
	SignalBus.connect_mode_enabled = enabled
	if enabled:
		SignalBus.disconnect_mode_enabled = false
		_disconnect_toggle.set_state_silent(false)
	_clear_source()
	SignalBus.connect_mode_toggled.emit(enabled)

func _on_disconnect_toggled(enabled: bool) -> void:
	SignalBus.disconnect_mode_enabled = enabled
	if enabled:
		SignalBus.connect_mode_enabled = false
		_connect_toggle.set_state_silent(false)
	_clear_source()
	SignalBus.disconnect_mode_toggled.emit(enabled)

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

func _on_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle()
		get_viewport().set_input_as_handled()

func _on_tab_mouse_entered() -> void:
	create_tween().tween_property(_tab, "modulate", Color(1.2, 1.2, 1.2), 0.10)

func _on_tab_mouse_exited() -> void:
	create_tween().tween_property(_tab, "modulate", Color(1.0, 1.0, 1.0), 0.10)
