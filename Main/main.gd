extends Node2D

@onready var click_counter: PanelContainer = $HUD/Counter

var placement_type  : String = ""
var placement_cost  : int = 0
var ghost           : Node2D = null

const GHOST_SCENE = preload("res://UI/Placement/placement_ghost.tscn")
const ENTITY_SCENES := {
	"Computer": preload("res://Clickers/Computer/computer.tscn"),
	"Switch": preload("res://Clickers/Switch/switch.tscn"),
}
const CONN_LINE_SCENE = preload("res://UI/HUD/ConnectionLine/network_overlay.tscn")


func _enter_tree() -> void:
	SignalBus.entity_purchase_requested.connect(_on_entity_purchase_requested)
	SignalBus.tech_purchase_requested.connect(_on_tech_purchase_requested)


func _ready() -> void:
	var conn_line = CONN_LINE_SCENE.instantiate()
	conn_line.z_index = -1
	add_child(conn_line)


func _process(_delta: float) -> void:
	if ghost:
		ghost.global_position = SignalBus.snap_to_grid(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if ghost == null:
		return

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				confirm_placement()
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_RIGHT:
				cancel_placement()
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_placement()
		get_viewport().set_input_as_handled()


func _on_entity_purchase_requested(clicker_type: String, cost: int) -> void:
	if ghost != null or click_counter.total_bits < cost:
		return

	click_counter.total_bits -= cost
	click_counter.update_counter()

	placement_type = clicker_type
	placement_cost = cost

	ghost = GHOST_SCENE.instantiate()
	ghost.setup(clicker_type)
	add_child(ghost)
	ghost.global_position = SignalBus.snap_to_grid(get_global_mouse_position())

	SignalBus.placement_started.emit(clicker_type)


func confirm_placement() -> void:
	var pos := SignalBus.snap_to_grid(get_global_mouse_position())

	if is_grid_slot_blocked(pos):
		return

	ghost.queue_free()
	ghost = null

	spawn_entity(placement_type, pos)

	placement_type = ""
	placement_cost = 0
	SignalBus.placement_ended.emit()


func is_grid_slot_blocked(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("Clickers"):
		if node.global_position == pos:
			return true
	return false


func cancel_placement() -> void:
	click_counter.total_bits += placement_cost
	click_counter.update_counter()

	if ghost != null:
		ghost.queue_free()
		ghost = null

	placement_type = ""
	placement_cost = 0
	SignalBus.placement_ended.emit()


func spawn_entity(clicker_type: String, pos: Vector2) -> void:
	if not ENTITY_SCENES.has(clicker_type):
		return

	var entity = ENTITY_SCENES[clicker_type].instantiate()
	add_child(entity)
	entity.global_position = SignalBus.snap_to_grid(pos)

	EventLog.log("+", "New %s added to the grid." % clicker_type)


func _on_tech_purchase_requested(id: StringName, cost: int) -> void:
	if click_counter.total_bits < cost:
		return

	click_counter.total_bits -= cost
	click_counter.update_counter()

	SignalBus.unlocked_techs.append(id)
	SignalBus.tech_unlocked.emit(id)

	var tech := TechRegistry.get_tech(id)
	EventLog.log("*", "Tech unlocked: %s." % tech.display_name)