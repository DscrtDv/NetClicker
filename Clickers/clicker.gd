extends Node2D
class_name Clicker 

signal bits_updated(bit_ps : int, is_boosted : bool)

@export var clicker_type : String    = "Clicker"
@export var bit_ps : int             = 1
@export var boost : int              = 1
@export var is_boosted : bool        = false

func _ready() -> void:
    add_to_group("Clickers")

func get_bit_ps() -> int:
    print ("ïs_boosted: ", is_boosted, " boost: ", boost, " bit_ps: ", bit_ps)
    if is_boosted:
        return bit_ps * boost
    return bit_ps

func enable_boost() -> void:
    is_boosted = true
    print("[+] BOOST :", is_boosted, " value = ", boost)
    bits_updated.emit(get_bit_ps(), is_boosted)

func disable_boost() -> void:
    is_boosted = false
    print("[+] BOOST :", is_boosted, " value = ", boost)
    bits_updated.emit(get_bit_ps(), is_boosted)