extends Node2D

@onready var click_counter : Node2D = $Counter

var total_bits : int = 0
var main_bits_ps : int = 0

func _enter_tree() -> void:
    SignalBus.clicker_spawned.connect(_on_clicker_spawned)


func recalculate_bits() -> void:
    main_bits_ps = 0
    var all_clickers = get_tree().get_nodes_in_group("Clickers")
    
    for clicker in all_clickers:
        print("[!]Checking clicker: ", clicker.clicker_type)
        if clicker is Computer and clicker.powered:
            main_bits_ps += clicker.get_bit_ps()
            
    click_counter.bits_ps = main_bits_ps
    print("[!] Total bits_ps recalculated: ", main_bits_ps)

func _on_bits_updated(bit_ps : int, is_boosted : bool) -> void:
    recalculate_bits()

func _on_computer_on(bit_ps : int) -> void:
    main_bits_ps += bit_ps
    click_counter.bits_ps = main_bits_ps
    print("[!]Main bits_ps updated: ", main_bits_ps)

func _on_computer_off(bit_ps : int) -> void:
    print("[!]Computer off with bit_ps: ", bit_ps)
    main_bits_ps -= bit_ps
    click_counter.bits_ps = main_bits_ps

func _on_clicker_spawned(clicker : Clicker) -> void:
    print("[!]Clicker spawned: ", clicker.clicker_type)
    if (clicker.clicker_type == "Computer"):
        clicker.computer_on.connect(_on_computer_on)
        clicker.computer_off.connect(_on_computer_off)
        clicker.bits_updated.connect(_on_bits_updated)
        print("[!]Computer connected to Main")