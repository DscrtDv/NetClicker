extends Polygon2D

func _ready() -> void:
	var s := 10.0
	polygon = PackedVector2Array([
		Vector2(-s, -s), Vector2( s, -s),
		Vector2( s,  s), Vector2(-s,  s),
	])
