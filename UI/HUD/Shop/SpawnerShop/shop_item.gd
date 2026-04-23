extends PanelContainer

@export var clicker_type  : String      = "Computer"
@export var entity_scene  : PackedScene

@onready var name_label  : Label  = $Margin/HBox/Info/NameLabel
@onready var price_label : Label  = $Margin/HBox/Info/PriceLabel
@onready var buy_btn     : Button = $Margin/HBox/BuyBtn

var _base_price  : int   = 10
var _price_scale : float = 1.15

func _ready() -> void:
	buy_btn.focus_mode = Control.FOCUS_NONE
	if entity_scene:
		var temp := entity_scene.instantiate()
		temp.init_prices()
		_base_price  = temp.base_price
		_price_scale = temp.price_scale
		temp.free()
	name_label.text = clicker_type.to_upper()
	SignalBus.clicker_spawned.connect(func(_n: Node)    -> void: _refresh())
	SignalBus.bits_changed.connect(func(_b: int)        -> void: _update_affordability())
	SignalBus.placement_started.connect(func(_t: String) -> void: buy_btn.disabled = true)
	SignalBus.placement_ended.connect(func()             -> void: _update_affordability())
	_refresh()

func _get_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("Clickers"):
		if node.get("clicker_type") == clicker_type:
			count += 1
	return count

func _current_price() -> int:
	return int(_base_price * pow(_price_scale, _get_count()))

func _refresh() -> void:
	price_label.text = "%d bits" % _current_price()
	_update_affordability()

func _update_affordability() -> void:
	buy_btn.disabled = SignalBus.total_bits < _current_price()

func _on_buy_btn_pressed() -> void:
	SignalBus.entity_purchase_requested.emit(clicker_type, _current_price())
