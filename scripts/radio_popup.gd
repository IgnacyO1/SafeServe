extends Control
@onready var original_position_x = position.x
@onready var label = $Label
@onready var sprite = $"Sprite2D2"
func show_radio_message(text : String, audio_file_path : String = "", greg_speaking : bool = false):
	sprite.set_flip_h(greg_speaking)
	if greg_speaking:
		position.x = original_position_x + 375
	else:
		position.x = original_position_x
	label.text = text
	visible = true
	if audio_file_path != "":
		var audio = find_child("AudioStreamPlayer2D")
		audio.stream = load(audio_file_path)
		audio.play()
		await audio.finished
		audio.stream = null
	else:
		print("Timer start")
		await get_tree().create_timer(3.0).timeout
		print("Timer end")
		
		pass
	visible = false
	
