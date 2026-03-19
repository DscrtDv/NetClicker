extends Node2D

@onready var counter_label : Label 	= $CounterLabel
@onready var timer : Timer 			= $Timer
var total_bits : int				= 0
var bits_ps : int 					= 0

func _ready() -> void:
	update_counter()
	timer.wait_time = 1.0
	timer.start()

func update_counter() -> void:
	counter_label.text = "%015d" % total_bits

func _on_timer_timeout() -> void:
	if (bits_ps > 0):
		total_bits += bits_ps
		update_counter()
