extends Clicker
class_name Computer

signal computer_on(bit_ps: int)
signal computer_off(bit_ps: int)

func init_prices() -> void:
	bit_ps      = 1
	base_price  = 0
	price_scale = 1.50

func _ready() -> void:
	super._ready()
	clicker_type   = "Computer"

func _on_power_changed(on: bool) -> void:
	if on:
		computer_on.emit(get_bit_ps())
	else:
		computer_off.emit(get_bit_ps())
