extends PanelContainer

@onready var _name_label : Label = $Margin/VBox/NameLabel
@onready var _desc_label : Label = $Margin/VBox/DescLabel
@onready var _cost_value : Label = $Margin/VBox/Grid/CostValue

var _anchor : Control = null

func _ready() -> void:
	visible = false
	SignalBus.tech_tooltip_show.connect(_on_show)
	SignalBus.tech_tooltip_hide.connect(_on_hide)

func _process(_delta: float) -> void:
	if _anchor and visible:
		_update_position()

func _on_show(data: TechData, anchor: Control) -> void:
	_anchor = anchor
	_name_label.text = data.display_name.to_upper()
	_desc_label.text = data.description

	if data.id in SignalBus.unlocked_techs:
		_cost_value.text     = "OWNED"
		_cost_value.modulate = Color(1.00, 0.78, 0.20)
	else:
		_cost_value.text     = "%d bits" % data.price
		_cost_value.modulate = Color(0.20, 0.85, 0.60) \
			if SignalBus.total_bits >= data.price \
			else Color(0.85, 0.35, 0.30)

	visible = true
	# Defer so the panel has one frame to compute its size before clamping
	call_deferred("_update_position")

func _on_hide() -> void:
	visible = false
	_anchor = null

func _update_position() -> void:
	var rect := _anchor.get_global_rect()
	position  = Vector2(rect.end.x + 8.0, rect.position.y)
	var vp    := get_viewport_rect().size
	position.x = clamp(position.x, 4.0, vp.x - size.x - 4.0)
	position.y = clamp(position.y, 4.0, vp.y - size.y - 4.0)
