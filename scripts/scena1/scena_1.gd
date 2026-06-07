extends Node
class_name scena1
var unit
var emergency 
var main_event = false

@onready var bottom_panel : Scena1BottomPanel = $"BottomPanel"
@onready var side_panel = $"SidePanel"
@onready var map_container : MapContainer = $"MapView/SubViewportContainer/SubViewport/MapRoot/MapContainer"
@onready var radio = $"HUD/Radio popup"
@onready var radio_glow = $"HUD/RadioSpriteGlow"
@onready var modal = $"General purpose modal"



func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_1.tscn")
	

func message( event : MapEvent ) -> void:
	
	if event.type in ["Crime", "Emergency", "Fire"]:
		bottom_panel.display_event(event)
		emergency = event
		if main_event:
			map_container.map_locked = true
			find_child("Message modal").visible = true
	else:
		#side_panel.find_child("Label").text = localization[event.type]
		#side_panel.find_child("Icon").texture = event.marker.texture_normal
		unit = event
	if unit and emergency:
		bottom_panel.find_child("Send").visible = true

func _send_unit():
	const unit_to_emergency = {
		"Fire rescue" : "Fire",
		"Police" : "Crime",
		"Ambulance" : "Emergency",
	}
	if emergency.type == unit_to_emergency[unit.type]:
		unit.delete()
		emergency.delete()
		modal.show_message("Jednostka wysłana")
		unit = null
		emergency = null
		side_panel.find_child("Send").visible = false
		bottom_panel.find_child("Label").text = ""
		bottom_panel.find_child("Icon").texture = null
		bottom_panel.find_child("Desc").text = ""
		side_panel.find_child("Label").text = ""
		side_panel.find_child("Icon").texture = null
	else:
		modal.show_message("Ups! Źle przydzielona jednostka")

func _main_event():
	if map_container.any_emergencies:
		return
	main_event = true
	modal.show_message("Uwaga! Nowe zgłoszenie!")
	map_container.spawn_event("Fire", Vector2(230, 2300))
	
func begin_radio_call():
	radio_glow.start_glow()
	find_child("RadioSprite").clickable = true
