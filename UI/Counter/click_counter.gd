extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _ready() -> void:
	counter_label.text = "%015d" % clicks

var clicks: int = 0

@onready var counter_label: Label = $CounterLabel

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		clicks += 1
	counter_label.text = "%015d" % clicks
