extends FloatingWindow

func _ready() -> void:
	super()
	SignalBus.tech_window_toggled.connect(_on_signal_toggled)
	closed.connect(func(): SignalBus.tech_window_toggled.emit(false))

func _on_signal_toggled(is_open: bool) -> void:
	if is_open:
		open()
	else:
		close()
