extends Node2D
class_name Clicker 

@export var clicker_type : String    = "Clicker"
@export var bit_ps : int             = 0
@export var boost : int              = 0
@export var is_boosted : bool        = false

func get_bit_ps() -> int:
    if is_boosted:
        return bit_ps * boost
    return bit_ps

func enable_boost() -> void:
    is_boosted = true

func disable_boost() -> void:
    is_boosted = false