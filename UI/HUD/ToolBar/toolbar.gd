extends HBoxContainer

@onready var tips_toggle       : HudToggle = $TipsToggle
@onready var ptr_toggle        : HudToggle = $PtrToggle
@onready var connect_toggle    : HudToggle = $ConnectToggle
@onready var disconnect_toggle : HudToggle = $DisconnectToggle

func _ready() -> void:
	tips_toggle.toggled.connect(func(enabled: bool) -> void:
		SignalBus.tooltip_enabled = enabled
		SignalBus.tooltip_toggled.emit(enabled)
	)
	ptr_toggle.toggled.connect(func(enabled: bool) -> void:
		SignalBus.pointer_enabled = enabled
		SignalBus.pointer_toggled.emit(enabled)
	)
	connect_toggle.toggled.connect(_on_connect_toggled)
	disconnect_toggle.toggled.connect(_on_disconnect_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if SignalBus.connect_mode_enabled:
			connect_toggle.public_toggle()
			get_viewport().set_input_as_handled()
		elif SignalBus.disconnect_mode_enabled:
			disconnect_toggle.public_toggle()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				connect_toggle.public_toggle()
				get_viewport().set_input_as_handled()
			KEY_X:
				disconnect_toggle.public_toggle()
				get_viewport().set_input_as_handled()

func _clear_source() -> void:
	if SignalBus.connection_source != null:
		SignalBus.connection_source = null
		SignalBus.connection_cancelled.emit()

func _on_connect_toggled(enabled: bool) -> void:
	SignalBus.connect_mode_enabled = enabled
	if enabled:
		SignalBus.disconnect_mode_enabled = false
		disconnect_toggle.set_state_silent(false)
	_clear_source()
	SignalBus.connect_mode_toggled.emit(enabled)

func _on_disconnect_toggled(enabled: bool) -> void:
	SignalBus.disconnect_mode_enabled = enabled
	if enabled:
		SignalBus.connect_mode_enabled = false
		connect_toggle.set_state_silent(false)
	_clear_source()
	SignalBus.disconnect_mode_toggled.emit(enabled)
