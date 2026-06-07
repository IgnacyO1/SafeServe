extends TextureButton

var radio
var clickable : bool = false

func _ready() -> void:
	radio = get_tree().current_scene
	print(radio)

func _click():
	if not clickable:
		return
	radio = radio.radio
	radio.sprite.set_flip_h(true)
	radio.position.x += 375
	get_tree().current_scene.radio.show_radio_message("Nie ma żadnego wolnego wozu strażackiego, co mam robić?", "")
	await get_tree().create_timer(3.0).timeout
	radio.sprite.set_flip_h(false)
	radio.position.x -= 375
	get_tree().current_scene.radio.show_radio_message("W remizie jest jeden zapasowy wóz, pojedź nim z Robertem ", "")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/scena_2.tscn")
	
