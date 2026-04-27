class_name TechNode
extends Control

enum State { LOCKED, AVAILABLE, UNLOCKED }

@onready var _panel       : PanelContainer = $Panel
@onready var _icon        : TextureRect    = $Panel/Margin/VBox/Icon
@onready var _name_label  : Label          = $Panel/Margin/VBox/NameLabel
@onready var _price_label : Label          = $Panel/Margin/VBox/PriceLabel

@export var style_locked    : StyleBoxFlat
@export var style_available : StyleBoxFlat
@export var style_unlocked  : StyleBoxFlat

var _data  : TechData
var _state : State = State.LOCKED

func setup(data: TechData) -> void:
	_data = data
	_name_label.text = data.display_name.to_upper()
	if data.icon:
		_icon.texture = data.icon
	else:
		_icon.visible = false
	_price_label.text = "%d b" % data.price
	refresh_state()

func _ready() -> void:
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	SignalBus.bits_changed.connect(func(_b: int) -> void: refresh_state())
	SignalBus.tech_unlocked.connect(func(_id: StringName) -> void: refresh_state())

func refresh_state() -> void:
	if _data == null:
		return
	if _data.id in SignalBus.unlocked_techs:
		_set_state(State.UNLOCKED)
	elif _parents_unlocked() \
			and SignalBus.total_bits >= _data.price:
		_set_state(State.AVAILABLE)
	else:
		_set_state(State.LOCKED)

func _parents_unlocked() -> bool:
	for pid in _data.parent_ids:
		if pid not in SignalBus.unlocked_techs:
			return false
	return true

func _set_state(s: State) -> void:
	_state = s
	match s:
		State.LOCKED:
			_panel.add_theme_stylebox_override("panel", style_locked)
			modulate = Color(1, 1, 1, 0.75)
			_price_label.visible = true
		State.AVAILABLE:
			_panel.add_theme_stylebox_override("panel", style_available)
			modulate = Color.WHITE
			_price_label.visible = true
		State.UNLOCKED:
			_panel.add_theme_stylebox_override("panel", style_unlocked)
			modulate = Color.WHITE
			_price_label.visible = false

func _on_hover(entered: bool) -> void:
	if _data == null:
		return
	if entered:
		SignalBus.tech_tooltip_show.emit(_data, self)
		if _state == State.AVAILABLE:
			modulate = Color(1.12, 1.12, 1.12)
	else:
		SignalBus.tech_tooltip_hide.emit()
		if _state == State.AVAILABLE:
			modulate = Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if _state != State.AVAILABLE:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		SignalBus.tech_purchase_requested.emit(_data.id, _data.price)
		get_viewport().set_input_as_handled()
