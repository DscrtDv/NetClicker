extends Control

const TERMINAL_W     := 280.0
const TAB_H          := 38.0
const CONTENT_H      := 220.0
const SLIDE_DURATION := 0.25
const MAX_ENTRIES    := 50

const BORDER_OPEN   := Color(0.192, 0.718, 0.643, 0.90)
const BORDER_CLOSED := Color(0.250, 0.250, 0.250, 0.90)

const SYMBOL_COLORS := {
	"+": "#6abf69",
	"$": "#ffd54f",
	"*": "#b39ddb",
	"!": "#ef5350",
}

var _open    : bool          = false
var _entries : Array[String] = []

@onready var _tab     : PanelContainer = $Tab
@onready var _sidebar : PanelContainer = $Sidebar
@onready var _log     : RichTextLabel  = $Sidebar/Margin/Log

var _style_tab     : StyleBoxFlat
var _style_sidebar : StyleBoxFlat

func _ready() -> void:
	_style_tab     = _tab.get_theme_stylebox("panel").duplicate()
	_style_sidebar = _sidebar.get_theme_stylebox("panel").duplicate()
	_tab.add_theme_stylebox_override("panel", _style_tab)
	_sidebar.add_theme_stylebox_override("panel", _style_sidebar)
	offset_top = -TAB_H
	EventLog.event_logged.connect(_on_event_logged)

func _toggle() -> void:
	_open = not _open
	var target       := -(TAB_H + CONTENT_H) if _open else -TAB_H
	var border_color := BORDER_OPEN if _open else BORDER_CLOSED
	create_tween() \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUINT) \
		.tween_property(self, "offset_top", target, SLIDE_DURATION)
	var t := create_tween()
	t.tween_property(_style_tab,     "border_color", border_color, SLIDE_DURATION)
	t.parallel().tween_property(_style_sidebar, "border_color", border_color, SLIDE_DURATION)

func _on_event_logged(symbol: String, message: String) -> void:
	var col  : String = SYMBOL_COLORS.get(symbol, "#ffffff")
	var line : String = "[color=%s][%s] %s[/color]" % [col, symbol, message]
	_entries.append(line)
	if _entries.size() > MAX_ENTRIES:
		_entries = _entries.slice(-MAX_ENTRIES)
		_log.clear()
		_log.append_text("\n".join(_entries))
	else:
		if _entries.size() > 1:
			_log.append_text("\n" + line)
		else:
			_log.append_text(line)
	_log.scroll_to_line(_log.get_line_count() - 1)

func _on_tab_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle()
		get_viewport().set_input_as_handled()

func _on_tab_mouse_entered() -> void:
	create_tween().tween_property(_tab, "modulate", Color(1.2, 1.2, 1.2), 0.10)

func _on_tab_mouse_exited() -> void:
	create_tween().tween_property(_tab, "modulate", Color(1.0, 1.0, 1.0), 0.10)
