extends Polygon2D

func _ready() -> void:
    var points := PackedVector2Array()
    var radius := 10.0
    var steps := 16
    for i in steps:
        var angle := (TAU / steps) * i
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    polygon = points
