extends TextureButton

var radio
var clickable : bool = true

func _ready() -> void:
	radio = get_tree().current_scene
	print(radio)

func _click():
	if not clickable:
		return
	radio = radio.radio
	await get_tree().current_scene.radio.show_radio_message("Nie ma żadnego wolnego wozu strażackiego, co mam robić?", "", true)
	await get_tree().current_scene.radio.show_radio_message("W remizie jest jeden zapasowy wóz, pojedź nim z Robertem ", "")
	get_tree().change_scene_to_file("res://scenes/scena_2.tscn")
	
	
