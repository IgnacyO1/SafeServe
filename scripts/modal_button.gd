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
	var message_modal = get_parent()
	var audio = message_modal.find_child("AudioStreamPlayer2D")
	var sound_icon = message_modal.get_node("SoundIcon")
	var notification = get_tree().current_scene.get_node("Notification popup")
	var sound_wave = notification.get_node("SoundWave")
	var time = 0.0

	sound_icon.visible = true
	notification.visible = true
	audio.play()
	while audio.playing:
		time += 0.05
		sound_wave.position.y = 100 + sin(time * 12.0) * 8.0
		await get_tree().create_timer(0.05).timeout
	sound_icon.visible = false
	notification.visible = false
	get_tree().current_scene.radio.show_radio_message("Nie mamy jednostek, będziesz musiał jechać sam ", "res://assets/Sounds/nie_mamy_wolnych_jednostek.mp3")
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/scena_2.tscn")
