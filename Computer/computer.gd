extends Sprite2D

var mouse_over = false

func _ready():
    pass

func _input(event):
    if mouse_over and event.is_action_pressed("mouse_click"):
        print("Computer clicked")
        

func _process(delta):
    pass

func _on_mouse_entered() -> void:
    print("Mouse entered computer")
    mouse_over = true  


func _on_mouse_exited() -> void:
    print("Mouse exited computer")
    mouse_over = false