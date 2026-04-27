class_name TechData
extends Resource

@export var id                : StringName
@export var display_name      : String
@export var price             : int
@export var description       : String
@export var tree_position     : Vector2i
@export var parent_ids        : Array[StringName] = []
@export var icon              : Texture2D
@export var effect            : Dictionary = {}
