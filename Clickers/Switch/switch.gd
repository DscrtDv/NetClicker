extends Clicker
class_name Switch

func init_prices() -> void:
    bit_ps      = 0
    base_price  = 0
    price_scale = 2.0

func _ready() -> void:
    super._ready()
    clicker_type    = "Switch"
    max_connections = 8

func blocks_traversal() -> bool:
    return not powered

func _on_power_changed(_on: bool) -> void:
    NetworkManager.rebuild()
    SignalBus.connection_formed.emit(null, null)
