extends PanelContainer

@onready var counter_label : Label   = $MarginContainer/VBoxContainer/HBoxContainer/CounterLabel
@onready var bps_container : Control = $MarginContainer/VBoxContainer/BpsContainer
@onready var bps_label     : Label   = $MarginContainer/VBoxContainer/BpsContainer/BpsLabel
@onready var timer         : Timer   = $Timer
var total_bits : int = 0
var bits_ps    : int = 0

var collapsed_h : float = 0.0
var expanded_h  : float = 0.0
var bps_h       : float = 0.0

func _ready() -> void:
	update_counter()
	timer.wait_time = 1.0
	timer.start()
	bps_container.custom_minimum_size.y = 0.0
	await get_tree().process_frame
	bps_h = bps_label.get_minimum_size().y
	reset_size()
	await get_tree().process_frame
	collapsed_h = size.y
	expanded_h = collapsed_h + bps_h + 3

func format_bits(n: int) -> String:
	var s := "%06d" % n
	var result := ""
	for i in range(s.length() - 1, -1, -1):
		var pos := s.length() - 1 - i
		if pos > 0 and pos % 3 == 0:
			result = " " + result
		result = s[i] + result
	return result

func update_counter() -> void:
	counter_label.text = format_bits(total_bits)
	bps_label.text = "%s bits/s" % format_bits(bits_ps)

func _on_timer_timeout() -> void:
	if bits_ps > 0:
		total_bits += bits_ps
		update_counter()

func _on_mouse_entered() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(bps_container, "custom_minimum_size:y", bps_h, 0.15)
	tw.tween_property(self, "size:y", expanded_h, 0.15)
	tw.tween_property(bps_label, "modulate:a", 1.0, 0.15)

func _on_mouse_exited() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(bps_container, "custom_minimum_size:y", 0.0, 0.15)
	tw.tween_property(self, "size:y", collapsed_h, 0.15)
	tw.tween_property(bps_label, "modulate:a", 0.0, 0.15)
