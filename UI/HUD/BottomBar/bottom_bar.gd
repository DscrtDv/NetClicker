extends HBoxContainer

@onready var tips_toggle : HudToggle = $TipsToggle
@onready var ptr_toggle  : HudToggle = $PtrToggle

func _ready() -> void:
	tips_toggle.toggled.connect(func(enabled: bool) -> void:
		SignalBus.tooltip_enabled = enabled
		SignalBus.tooltip_toggled.emit(enabled)
	)
	ptr_toggle.toggled.connect(func(enabled: bool) -> void:
		SignalBus.pointer_enabled = enabled
		SignalBus.pointer_toggled.emit(enabled)
	)
