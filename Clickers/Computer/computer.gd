extends Clicker
class_name Computer

@onready var screen     := $Screen

signal computer_on(bit_ps : int)
signal computer_off(bit_ps : int) 

var mouse_over          := false
var grabbing            := false
var powered             := false
var mousePos : Vector2  = Vector2.ZERO
var deltaPos : Vector2  = Vector2.ZERO

var screen_on_color : Color = Color(0.192, 0.718, 0.643)
var screen_off_color : Color = Color(0.2, 0.2, 0.2) # Dark gray

var hover_scale := Vector2(1.05, 1.05)
var normal_scale := Vector2(1.0, 1.0)


func _ready() -> void:
	screen.modulate = screen_off_color
	clicker_type = "Computer"
	SignalBus.clicker_spawned.emit(self)

func _process(_delta: float) -> void:
	deltaPos = mousePos - get_global_mouse_position()
	mousePos = get_global_mouse_position()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("left_click") and mouse_over or grabbing:
		global_position -= deltaPos
		grabbing = true
	if Input.is_action_just_released("left_click"):
		if grabbing:
			grabbing = false
	if Input.is_action_just_pressed("right_click") and mouse_over:
		powered = not powered
		print("[!]Computer state changed ", powered)
		if powered:
			print("[!]Computer powered on")
			if mouse_over:
				boost = 2
				enable_boost()
			screen.modulate = screen_on_color
			computer_on.emit(get_bit_ps())
		else:
			print("[!]Computer powered off")
			screen.modulate = screen_off_color
			if is_boosted:
				disable_boost()
			computer_off.emit(get_bit_ps())

func _on_mouse_entered() -> void:
	mouse_over = true
	if (powered):
		boost = 2
		enable_boost()
	var tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.15)

func _on_mouse_exited() -> void:
	if not grabbing:
		mouse_over = false
		boost = 1
		if is_boosted:
			disable_boost()
		var tween = create_tween()
		tween.tween_property(self, "scale", normal_scale, 0.15)
