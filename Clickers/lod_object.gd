extends Node2D
class_name LODObject

func _ready() -> void:
	SignalBus.lod_changed.connect(_on_lod_changed)
	_on_lod_changed(SignalBus.current_lod)

func _on_lod_changed(level: int) -> void:
	var detail := get_node_or_null("DetailView")
	var proxy  := get_node_or_null("ProxyView")
	if detail: detail.visible = level == 0
	if proxy:  proxy.visible  = level == 1
