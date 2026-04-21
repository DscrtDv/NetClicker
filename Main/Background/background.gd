extends Node2D

const BG_COLOR        := Color(0.04, 0.06, 0.08, 1.0)
const DOT_COLOR       := Color(0.25, 0.45, 0.55, 0.30)
const DOT_LARGE_COLOR := Color(0.30, 0.55, 0.65, 0.60)
const SPACING         := 40.0
const LARGE_EVERY     := 4
const DOT_RADIUS      := 1.0
const DOT_LARGE_RADIUS := 2.5

var _large_only := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(BG_COLOR)
	SignalBus.lod_changed.connect(func(level: int) -> void:
		_large_only = level > 0
	)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var inv := get_viewport_transform().affine_inverse()
	var vp  := get_viewport_rect()
	var tl  := inv * vp.position
	var br  := inv * (vp.position + vp.size)

	draw_rect(Rect2(tl, br - tl), BG_COLOR)

	var sx : float = floor(tl.x / SPACING) * SPACING
	var sy : float = floor(tl.y / SPACING) * SPACING

	var x : float = sx
	while x <= br.x + SPACING:
		var y : float = sy
		while y <= br.y + SPACING:
			var gx := int(round(x / SPACING))
			var gy := int(round(y / SPACING))
			if gx % LARGE_EVERY == 0 and gy % LARGE_EVERY == 0:
				draw_circle(Vector2(x, y), DOT_LARGE_RADIUS, DOT_LARGE_COLOR)
			elif not _large_only:
				draw_circle(Vector2(x, y), DOT_RADIUS, DOT_COLOR)
			y += SPACING
		x += SPACING
