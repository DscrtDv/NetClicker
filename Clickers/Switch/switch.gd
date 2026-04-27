extends Clicker
class_name Switch

var max_computer_connections : int = 5
var max_switch_connections   : int = 3

func init_prices() -> void:
    bit_ps      = 0
    base_price  = 0
    price_scale = 2.0

func _ready() -> void:
    super._ready()
    clicker_type    = "Switch"
    max_connections = max_computer_connections + max_switch_connections
    min_separation  = 32.0

func _has_any_slot() -> bool:
    var comp_cnt := 0
    var sw_cnt   := 0
    for c in connections:
        if c is Switch: sw_cnt   += 1
        else:           comp_cnt += 1
    return comp_cnt < max_computer_connections or sw_cnt < max_switch_connections

func _has_slot_for(src: Clicker) -> bool:
    var cnt := 0
    if src is Switch:
        for c in connections:
            if c is Switch: cnt += 1
        return cnt < max_switch_connections
    else:
        for c in connections:
            if not (c is Switch): cnt += 1
        return cnt < max_computer_connections

func blocks_traversal() -> bool:
    return not powered

func _on_power_changed(_on: bool) -> void:
    NetworkManager.rebuild()
    SignalBus.connection_formed.emit(null, null)
