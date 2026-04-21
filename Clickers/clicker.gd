extends LODObject
class_name Clicker 

signal bits_updated(bit_ps : int)

@export var clicker_type  : String = "Clicker"
@export var bit_ps        : int    = 1
@export var base_price      : int            = 0
@export var price_scale     : float           = 1.15
@export var min_separation  : float           = 32.0
@export var is_origin       : bool            = false
@export var max_connections : int             = 2
var connections             : Array[Clicker]  = []

func _ready() -> void:
    super._ready()
    add_to_group("Clickers")

func get_bit_ps() -> int:
    return bit_ps

func init_prices() -> void:
    pass

func connect_to(other: Clicker) -> void:
    if other not in connections:
        connections.append(other)
    if self not in other.connections:
        other.connections.append(self)

func disconnect_from(other: Clicker) -> void:
    connections.erase(other)
    other.connections.erase(self)