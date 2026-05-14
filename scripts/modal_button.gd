extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_press():
	get_parent().visible = false
func _begin_game():
	get_tree().current_scene.map_container.map_locked = false
