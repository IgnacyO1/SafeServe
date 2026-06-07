extends Control

@onready var label = $Label
@onready var sprite = $"Sprite2D2"
func show_radio_message(text : String, audio_file_path : String = ""):
	label.text = text
	visible = true
	if audio_file_path != "":
		var audio = find_child("AudioStreamPlayer2D")
		audio.stream = load(audio_file_path)
		audio.play()
		await audio.finished
		audio.stream = null
	else:
		await get_tree().create_timer(3.0).timeout
		pass
	visible = false
	
