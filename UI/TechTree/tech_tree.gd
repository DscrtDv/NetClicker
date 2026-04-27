extends FloatingWindow

const _TECH_NODE_SCENE := preload("res://UI/TechTree/TechNode/tech_node.tscn")
const _CELL_SIZE       := Vector2(130, 100)
const _PADDING         := Vector2(30, 30)
const _NODE_HALF       := Vector2(40, 35)  # half of TechNode's 80x70 size

@onready var _content : Control = $Window/Margin/VBox/Content

# Tooltip built in code — avoids CanvasLayer sizing issues with instanced scenes
var _tooltip        : PanelContainer  = null
var _tip_name       : Label           = null
var _tip_desc       : Label           = null
var _tip_cost       : Label           = null
var _tip_anchor     : Control         = null

func _ready() -> void:
	super()
	SignalBus.tech_window_toggled.connect(_on_signal_toggled)
	closed.connect(func(): SignalBus.tech_window_toggled.emit(false))
	_build_tree()
	_build_tooltip()

func _on_signal_toggled(is_open: bool) -> void:
	if is_open:
		open()
	else:
		close()

func _process(_delta: float) -> void:
	if _tooltip and _tooltip.visible and _tip_anchor:
		_position_tooltip()

# ---------------------------------------------------------------------------
# Tree layout
# ---------------------------------------------------------------------------

func _build_tree() -> void:
	var techs := TechRegistry.get_all()

	var max_col := 0
	var max_row := 0
	for data : TechData in techs:
		max_col = max(max_col, data.tree_position.x)
		max_row = max(max_row, data.tree_position.y)
	var canvas_size := Vector2(max_col, max_row) * _CELL_SIZE \
		+ Vector2(80, 70) + _PADDING * 2

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_content.add_child(scroll)

	var canvas := Control.new()
	canvas.custom_minimum_size = canvas_size
	canvas.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(canvas)

	var connector := _ConnectorLayer.new()
	connector.custom_minimum_size = canvas_size
	connector.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(connector)

	var centers : Dictionary = {}
	for data : TechData in techs:
		var node : TechNode = _TECH_NODE_SCENE.instantiate()
		var pos  := Vector2(data.tree_position) * _CELL_SIZE + _PADDING
		canvas.add_child(node)
		node.position = pos
		node.setup(data)
		centers[data.id] = pos + _NODE_HALF

	var lines : Array = []
	for data : TechData in techs:
		for parent_id : StringName in data.parent_ids:
			if centers.has(parent_id) and centers.has(data.id):
				lines.append([centers[parent_id], centers[data.id]])
	connector.setup(lines)

# ---------------------------------------------------------------------------
# Tooltip (built in code so there are no scene/UID loading issues)
# ---------------------------------------------------------------------------

func _build_tooltip() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.04, 0.92)
	bg.set_border_width_all(3)
	bg.border_color = Color(0.25, 0.25, 0.25, 0.90)
	bg.set_corner_radius_all(4)

	_tooltip = PanelContainer.new()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_theme_stylebox_override("panel", bg)
	_tooltip.visible = false
	add_child(_tooltip)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",     9)
	margin.add_theme_constant_override("margin_bottom",  9)
	_tooltip.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	_tip_name = _tip_label(12, Color.WHITE)
	vbox.add_child(_tip_name)

	vbox.add_child(_tip_separator())

	_tip_desc = _tip_label(9, Color(0.70, 0.70, 0.78))
	_tip_desc.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_tip_desc.custom_minimum_size  = Vector2(200, 0)
	vbox.add_child(_tip_desc)

	vbox.add_child(_tip_separator())

	_tip_cost = _tip_row(vbox, "COST")

	SignalBus.tech_tooltip_show.connect(_on_tooltip_show)
	SignalBus.tech_tooltip_hide.connect(_on_tooltip_hide)

func _tip_label(font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.modulate = color
	return lbl

func _tip_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.modulate = Color(0.30, 0.30, 0.35, 0.80)
	return sep

func _tip_row(parent: VBoxContainer, key: String) -> Label:
	return _tip_row_container(parent, key).get_child(1)

func _tip_row_container(parent: VBoxContainer, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var k := _tip_label(9, Color(0.55, 0.55, 0.65))
	k.text = key
	row.add_child(k)

	var v := _tip_label(9, Color.WHITE)
	row.add_child(v)
	return row

func _on_tooltip_show(data: TechData, anchor: Control) -> void:
	_tip_anchor  = anchor
	_tip_name.text = data.display_name.to_upper()
	_tip_desc.text = data.description

	if data.id in SignalBus.unlocked_techs:
		_tip_cost.text    = "OWNED"
		_tip_cost.modulate = Color(1.00, 0.78, 0.20)
	else:
		_tip_cost.text    = "%d bits" % data.price
		_tip_cost.modulate = Color(0.20, 0.85, 0.60) \
			if SignalBus.total_bits >= data.price \
			else Color(0.85, 0.35, 0.30)

	_tooltip.visible = true

func _on_tooltip_hide() -> void:
	_tooltip.visible  = false
	_tip_anchor = null

func _position_tooltip() -> void:
	var rect := _tip_anchor.get_global_rect()
	_tooltip.position = Vector2(rect.end.x + 8.0, rect.position.y)
	var vp := get_viewport_rect().size
	_tooltip.position.x = clamp(_tooltip.position.x, 4.0, vp.x - _tooltip.size.x - 4.0)
	_tooltip.position.y = clamp(_tooltip.position.y, 4.0, vp.y - _tooltip.size.y - 4.0)

# ---------------------------------------------------------------------------
# Connector line layer
# ---------------------------------------------------------------------------

class _ConnectorLayer extends Control:
	var _lines : Array = []

	func setup(lines: Array) -> void:
		_lines = lines
		queue_redraw()

	func _draw() -> void:
		for pair in _lines:
			draw_line(pair[0], pair[1], Color(0.30, 0.30, 0.38, 0.65), 1.5, true)
