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
	get_tree().current_scene.map_container.map_locked = false
	var audio = get_parent().find_child("AudioStreamPlayer2D")
	#audio.play()
	#await audio.finished
	get_tree().current_scene.radio.show_radio_message("Nie mamy jednostek, będziesz musiał jechać sam ")
	await get_tree().create_timer(10.0).timeout
	get_tree().change_scene_to_file("res://scenes/scena_2.tscn")
