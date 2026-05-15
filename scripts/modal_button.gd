extends TextureButton
func _ready() -> void:
	pass # Replace with function body.
func _process(_delta: float) -> void:
	pass

func _on_press():
	get_parent().visible = false
func _begin_game():
	get_tree().current_scene.map_container.map_locked = false
func _play_message():
	
	get_tree().change_scene_to_file("res://scenes/scena_2.tscn")
