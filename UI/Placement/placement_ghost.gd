extends Node2D

const _TEXTURES := {
	"Computer": preload("res://Clickers/Computer/computer.png"),
}

func setup(clicker_type: String) -> void:
	modulate     = Color(1.0, 1.0, 1.0, 0.55)
	z_index      = 10
	var sprite   : Sprite2D = $Sprite2D
	if clicker_type in _TEXTURES:
		sprite.texture = _TEXTURES[clicker_type]
