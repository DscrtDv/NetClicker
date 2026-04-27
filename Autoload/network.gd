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
	if is_mesh():
		total += ceili(members.size() / 2.0) + get_computer_count()
	elif is_ring():
		total += ceili(members.size() / 2.0)
	elif is_star():
		total += get_computer_count()
	if SignalBus.unlocked_techs.has(&"net_basics"):
		total += ceili(total * 0.2)
	return total

func get_size() -> int:
	return members.size()

func get_computer_count() -> int:
	var count := 0
	for m in members:
		if m is Computer:
			count += 1
	return count

# ── Pattern detection ──────────────────────────────────────────────────────

func get_pattern() -> String:
	if is_mesh(): return "mesh"
	if is_star(): return "star"
	if is_ring(): return "ring"
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
	var switches : Array = []
	var computers : Array = []
	for m in members:
		if m is Switch:
			switches.append(m)
		else:
			computers.append(m)

	if switches.size() != 1 or computers.size() < 3:
		return false

	var hub : Clicker = switches[0]

	if hub.connections.size() != computers.size():
		return false

	for conn in hub.connections:
		if conn not in computers:
			return false

	for comp in computers:
		if (comp as Clicker).connections.size() != 1 or (comp as Clicker).connections[0] != hub:
			return false

	return true

func is_mesh() -> bool:
	var switches : Array = []
	var computers : Array = []
	for m in members:
		if m is Switch:
			switches.append(m)
		else:
			computers.append(m)

	if switches.size() != 1 or computers.size() < 3:
		return false

	var hub : Clicker = switches[0]

	if hub.connections.size() != computers.size():
		return false
	for conn in hub.connections:
		if conn not in computers:
			return false

	# Each computer: exactly 3 connections — 1 to hub, 2 to computer peers
	for comp in computers:
		var c := comp as Clicker
		if c.connections.size() != 3:
			return false
		if hub not in c.connections:
			return false
		var peer_count := 0
		for conn in c.connections:
			if conn in computers:
				peer_count += 1
		if peer_count != 2:
			return false

	# Computer peers must form a single ring
	var visited : Dictionary = {}
	var queue : Array = [computers[0]]
	while not queue.is_empty():
		var node = queue.pop_front()
		if visited.has(node):
			continue
		visited[node] = true
		for c in (node as Clicker).connections:
			if c in computers and not visited.has(c):
				queue.append(c)
	return visited.size() == computers.size()
