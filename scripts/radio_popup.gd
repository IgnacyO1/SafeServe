extends Control

@onready var label = $Label
func show_radio_message(text : String):
	label.text = text
	visible = true
	await get_tree().create_timer(5.0).timeout
	visible = false
