class_name TechRegistry

# All techs indexed by id. Call TechRegistry.get_all() or TechRegistry.get_tech(id).
# Tree layout uses Vector2i(column, row). CELL_SIZE in the tree scene controls spacing.
#
# Effect keys (applied by TechManager, Milestone 5):
#   "max_network_bonus"       : int  — added to SignalBus.max_network_size
#   "unlock_switch"           : bool — makes the Switch purchasable in the shop
#   "computer_extra_slot"     : bool — gives computers a third connection slot
#   "switch_cross_network"    : bool — switches can connect across network boundaries

static var _techs : Dictionary  # StringName -> TechData

static func _ensure_loaded() -> void:
	if not _techs.is_empty():
		return
	_techs = {}
	for td : TechData in _build_all():
		_techs[td.id] = td

static func get_all() -> Array[TechData]:
	_ensure_loaded()
	var out : Array[TechData] = []
	for v in _techs.values():
		out.append(v)
	return out

static func get_tech(id: StringName) -> TechData:
	_ensure_loaded()
	return _techs.get(id, null)

# ---------------------------------------------------------------------------
# Tech definitions
# ---------------------------------------------------------------------------

static func _make(
	p_id               : StringName,
	p_display_name     : String,
	p_price            : int,
	p_description      : String,
	p_prerequisite_bits: int,
	p_tree_position    : Vector2i,
	p_parent_ids       : Array[StringName],
	p_effect           : Dictionary
) -> TechData:
	var td              := TechData.new()
	td.id               = p_id
	td.display_name     = p_display_name
	td.price            = p_price
	td.description      = p_description
	td.prerequisite_bits = p_prerequisite_bits
	td.tree_position    = p_tree_position
	td.parent_ids       = p_parent_ids
	td.effect           = p_effect
	return td

static func _build_all() -> Array[TechData]:
	return [
		# --- Column 0: Root ---
		_make(&"net_basics", "Network Basics", 50,
			"Foundational optimizations that improve every network you run.",
			0, Vector2i(0, 1), [], {}),

		# --- Column 1 ---
		_make(&"hard_drives", "Hard Drives", 200,
			"Additional storage capacity allows larger subnets. +2 max network size.",
			100, Vector2i(1, 0), [&"net_basics"], {"max_network_bonus": 2}),

		_make(&"switch", "Switch", 200,
			"Unlocks the Switch in the shop. Switches route traffic between multiple computers.",
			100, Vector2i(1, 2), [&"net_basics"], {"unlock_switch": true}),

		# --- Column 2 ---
		_make(&"computer_sockets", "Computer Sockets", 500,
			"Adds a third connection slot to every computer, increasing throughput potential.",
			300, Vector2i(2, 0), [&"hard_drives"], {"computer_extra_slot": true}),

		_make(&"underground_cables", "Underground Cables", 800,
			"Shielded underground lines let switches connect across network boundaries, ignoring size limits.",
			500, Vector2i(2, 2), [&"switch"], {"switch_cross_network": true}),
	]
