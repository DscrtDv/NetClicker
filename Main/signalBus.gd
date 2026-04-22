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