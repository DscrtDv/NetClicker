extends Node

var _networks       : Array[Network] = []
var _origin         : Node          = null
var _pattern_cache  : Dictionary    = {}  # net_key → last known pattern
var _name_cache : Dictionary = {}  # net_key → display_name

func _ready() -> void:
	SignalBus.clicker_spawned.connect(_on_clicker_spawned)

func _on_clicker_spawned(clicker: Node) -> void:
	if _origin == null:
		_origin = clicker
		if clicker.has_method("get") and clicker.get("is_origin") != null:
			clicker.is_origin = true
	rebuild()

func rebuild() -> void:
	# snapshot assimilation state before clearing
	var pre_node_is_main : Dictionary = {}  # node → bool
	var pre_node_banked  : Dictionary = {}  # node → share of banked bits
	var pre_node_netname : Dictionary = {}  # node → display_name
	for net in _networks:
		var share := net.banked_bits / float(max(net.members.size(), 1))
		for m in net.members:
			pre_node_is_main[m] = net.is_main
			pre_node_banked[m]  = share
			pre_node_netname[m] = net.display_name

	# transfer banked bits proportionally
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
			if not (clicker as Clicker).blocks_traversal():
				for c in (clicker as Clicker).connections:
					if not visited.has(c):
						queue.append(c)
		for m in net.members:
			net.banked_bits += old_banked.get(m, 0.0)
		_networks.append(net)

	# assign is_main
	for net in _networks:
		net.is_main = false
		for m in net.members:
			if m == _origin:
				net.is_main = true
				break

	# assign display names — stable across rebuilds via key cache
	for net in _networks:
		var key := _net_key(net)
		if net.is_main:
			net.display_name = "Main Network"
		elif _name_cache.has(key):
			net.display_name = _name_cache[key]
		else:
			net.display_name = "Sub-Net %s" % ("%04X" % (randi() % 0x10000))
		_name_cache[key] = net.display_name

	# prune cache entries for networks that no longer exist
	var live_keys : Dictionary = {}
	for net in _networks:
		live_keys[_net_key(net)] = true
	for key in _name_cache.keys():
		if not live_keys.has(key):
			_name_cache.erase(key)

	# propagate names back to each clicker node for tooltip display
	for net in _networks:
		for m in net.members:
			m.network_name = net.display_name

	if SignalBus.outlined_network != null and not has_network(SignalBus.outlined_network):
		SignalBus.outlined_network = get_main()

	_fire_events(pre_node_is_main, pre_node_banked, pre_node_netname)

func _fire_events(pre_is_main: Dictionary, pre_banked: Dictionary, pre_netname: Dictionary) -> void:
	# Assimilation: nodes that moved from a non-main network into main
	var main_net := get_main()
	if main_net != null:
		var absorbed : Dictionary = {}  # old net name → total banked bits
		for m in main_net.members:
			if pre_is_main.get(m, true):
				continue
			var net_name : String = pre_netname.get(m, "Sub-Net")
			absorbed[net_name] = absorbed.get(net_name, 0.0) + pre_banked.get(m, 0.0)
		for net_name in absorbed:
			EventLog.log("$", "%s assimilated by Main Network, %d bits added." \
				% [net_name, int(absorbed[net_name])])

	# Pattern formed / broken — compare against persistent cache
	for net in _networks:
		var key     := _net_key(net)
		var new_pat := net.get_pattern()
		var old_pat : String = _pattern_cache.get(key, "")
		_pattern_cache[key] = new_pat
		if new_pat == old_pat:
			continue
		if new_pat != "none":
			var bonus := ceili(net.members.size() / 2.0)
			EventLog.log("*", "New pattern formed: %s. Bonus of +%d bps for this network." \
				% [new_pat.capitalize(), bonus])
		elif old_pat != "none" and old_pat != "":
			EventLog.log("!", "Pattern broken in %s." % net.display_name)

func _net_key(net: Network) -> String:
	var ids : PackedInt64Array = PackedInt64Array()
	for m in net.members:
		ids.append(m.get_instance_id())
	ids.sort()
	var parts : PackedStringArray = PackedStringArray()
	for i in ids:
		parts.append(str(i))
	return ",".join(parts)

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

func has_network(net: Network) -> bool:
	return net in _networks

func get_main() -> Network:
	for net in _networks:
		if net.is_main:
			return net
	return null
