extends Node2D

@onready var popup = $"HUD/Radio popup"
@onready var label = $"HUD/Radio popup/Label"
# Called when the node enters the scene tree for the first time.
func show_radio_message(text : String):
	label.text = text
	popup.visible = true
	await get_tree().create_timer(5.0).timeout
	popup.visible = false
	
func _ready() -> void:
	await get_tree().create_timer(10.0).timeout
	show_radio_message("No name test message for testing")
