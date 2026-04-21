extends Node

var _networks : Array[Network] = []
var _origin   : Node          = null

func _ready() -> void:
	SignalBus.clicker_spawned.connect(_on_clicker_spawned)

func _on_clicker_spawned(clicker: Node) -> void:
	if _origin == null:
		_origin = clicker
		if clicker.has_method("get") and clicker.get("is_origin") != null:
			clicker.is_origin = true
	rebuild()

func rebuild() -> void:
	var old_banked : Dictionary = {}
	for net: Network in _networks:
		var share : float = net.banked_bits / float(max(net.members.size(), 1))
		for m in net.members:
			old_banked[m] = share

	_networks.clear()
	var visited : Dictionary = {}

	for node in get_tree().get_nodes_in_group("Clickers"):
		if visited.has(node):
			continue
		var net  := Network.new()
		var queue : Array = [node]
		while not queue.is_empty():
			var clicker = queue.pop_front()
			if visited.has(clicker):
				continue
			visited[clicker] = true
			net.members.append(clicker)
			for c in (clicker as Clicker).connections:
				if not visited.has(c):
					queue.append(c)
		for m in net.members:
			net.banked_bits += old_banked.get(m, 0.0)
		_networks.append(net)

	for net in _networks:
		net.is_main = false
		for m in net.members:
			if m == _origin:
				net.is_main = true
				break

func tick() -> int:
	var main_delta := 0
	for net in _networks:
		var bps := net.get_bps()
		if net.is_main:
			main_delta = bps
			if net.banked_bits >= 1.0:
				main_delta += int(net.banked_bits)
				net.banked_bits = 0.0
		else:
			net.banked_bits += float(bps)
	return main_delta

func get_network_for(clicker: Node) -> Network:
	for net in _networks:
		if clicker in net.members:
			return net
	return null

func get_main() -> Network:
	for net in _networks:
		if net.is_main:
			return net
	return null
