class_name Network
extends RefCounted

var members      : Array = []   # Array[Clicker]
var banked_bits  : float = 0.0
var is_main      : bool  = false
var display_name : String = ""

func get_bps() -> int:
	var total := 0
	for m in members:
		if m.get("powered") != false:
			total += m.bit_ps
	if is_ring():
		total += ceili(members.size() / 2.0)
	return total

func get_size() -> int:
	return members.size()

# ── Pattern detection ──────────────────────────────────────────────────────

func get_pattern() -> String:
	# if is_mesh(): return "mesh"
	# if is_star():  return "star"
	if is_ring():  return "ring"
	return "none"

func is_ring() -> bool:
	if members.size() < 3:
		return false
	for m in members:
		if (m as Clicker).connections.size() != 2:
			return false
	var visited : Dictionary = {}
	var queue   : Array      = [members[0]]
	while not queue.is_empty():
		var node = queue.pop_front()
		if visited.has(node):
			continue
		visited[node] = true
		for c in (node as Clicker).connections:
			if not visited.has(c):
				queue.append(c)
	return visited.size() == members.size()

func is_star() -> bool:
	if members.size() < 3:
		return false
	var expected_hub_deg := members.size() - 1
	var hub_count   := 0
	var spoke_count := 0
	for m in members:
		var deg := (m as Clicker).connections.size()
		if deg == expected_hub_deg:
			hub_count += 1
		elif deg == 1:
			spoke_count += 1
		else:
			return false
	return hub_count == 1 and spoke_count == members.size() - 1

func is_mesh() -> bool:
	var n := members.size()
	if n < 3:
		return false
	for m in members:
		if (m as Clicker).connections.size() != n - 1:
			return false
	return true
