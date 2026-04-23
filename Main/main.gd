extends Node2D

@onready var click_counter : PanelContainer = $HUD/Counter

var _placement_type : String = ""
var _placement_cost : int    = 0
var _ghost          : Node2D = null

const _GHOST_SCENE    := preload("res://UI/Placement/placement_ghost.tscn")
const _ENTITY_SCENES  := {
    "Computer": preload("res://Clickers/Computer/computer.tscn"),
    "Switch":   preload("res://Clickers/Switch/switch.tscn"),
}

var _placement_min_sep : float = 32.0

const _CONN_LINE_SCENE := preload("res://UI/HUD/ConnectionLine/network_overlay.tscn")

func _enter_tree() -> void:
    SignalBus.entity_purchase_requested.connect(_on_entity_purchase_requested)

func _ready() -> void:
    var conn_line      := _CONN_LINE_SCENE.instantiate()
    conn_line.z_index   = -1
    add_child(conn_line)

func _process(_delta: float) -> void:
    if _ghost:
        _ghost.global_position = get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
    if _ghost == null:
        return
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                _confirm_placement()
                get_viewport().set_input_as_handled()
            MOUSE_BUTTON_RIGHT:
                _cancel_placement()
                get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _cancel_placement()
        get_viewport().set_input_as_handled()

func _on_entity_purchase_requested(clicker_type: String, cost: int) -> void:
    if _ghost != null or click_counter.total_bits < cost:
        return
    if _ENTITY_SCENES.has(clicker_type):
        var temp := (_ENTITY_SCENES[clicker_type] as PackedScene).instantiate()
        _placement_min_sep = temp.min_separation
        temp.free()
    click_counter.total_bits -= cost
    click_counter.update_counter()
    _placement_type = clicker_type
    _placement_cost = cost
    _ghost = _GHOST_SCENE.instantiate()
    _ghost.setup(clicker_type)
    add_child(_ghost)
    _ghost.global_position = get_global_mouse_position()
    SignalBus.placement_started.emit(clicker_type)

func _confirm_placement() -> void:
    var pos := _ghost.global_position
    if _is_placement_overlapping(pos):
        return
    _ghost.queue_free()
    _ghost = null
    _spawn_entity(_placement_type, pos)
    _placement_type = ""
    _placement_cost = 0
    SignalBus.placement_ended.emit()

func _is_placement_overlapping(pos: Vector2) -> bool:
    for node in get_tree().get_nodes_in_group("Clickers"):
        if pos.distance_to(node.global_position) < _placement_min_sep:
            return true
    return false

func _cancel_placement() -> void:
    click_counter.total_bits += _placement_cost
    click_counter.update_counter()
    _ghost.queue_free()
    _ghost = null
    _placement_type = ""
    _placement_cost = 0
    SignalBus.placement_ended.emit()

func _spawn_entity(clicker_type: String, pos: Vector2) -> void:
    if not _ENTITY_SCENES.has(clicker_type):
        return
    var entity := (_ENTITY_SCENES[clicker_type] as PackedScene).instantiate()
    add_child(entity)
    entity.global_position = pos
    EventLog.log("+", "New %s added to the grid." % clicker_type)

