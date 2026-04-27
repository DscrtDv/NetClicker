extends Node

signal clicker_spawned(node : Node)
signal lod_changed(level : int)
signal tooltip_show(node_name: String, network: String, state: bool, bit_ps: int, anchor: Node2D)
signal tooltip_hide()
signal tooltip_toggled(enabled: bool)
signal pointer_toggled(enabled: bool)
signal entity_purchase_requested(clicker_type: String, cost: int)
signal bits_changed(total: int)
signal placement_started(clicker_type: String)
signal placement_ended()
signal network_tick()
signal connect_mode_toggled(enabled: bool)
signal disconnect_mode_toggled(enabled: bool)
signal tech_window_toggled(is_open: bool)
signal tech_unlocked(id: StringName)
signal tech_purchase_requested(id: StringName, cost: int)
signal tech_tooltip_show(data: TechData, anchor: Control)
signal tech_tooltip_hide()
signal connection_source_selected(clicker: Node)
signal connection_cancelled()
signal connection_formed(a: Node, b: Node)

var current_lod        : int    = 0
var tooltip_enabled    : bool   = true
var pointer_enabled    : bool   = true
var total_bits         : int    = 0
var entity_grabbed      : Node2D = null
var max_network_size    : int    = 5
var connect_mode_enabled   : bool = false
var disconnect_mode_enabled: bool = false
var connection_source      : Node = null

var outlined_network = null  # Network — set by main counter hover/pin
var hovered_network  = null  # Network — set by cursor proximity to a connection line
var unlocked_techs   : Array[StringName] = []

const GRID_SPACING := 40.0

func snap_to_grid(pos: Vector2) -> Vector2:
    return Vector2(
        round(pos.x / GRID_SPACING) * GRID_SPACING,
        round(pos.y / GRID_SPACING) * GRID_SPACING
    )