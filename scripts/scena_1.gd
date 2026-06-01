extends Node
class_name scena1
var unit
var emergency 
var main_event = false

@onready var top_panel = $"SidePanelTop"
@onready var bottom_panel = $"SidePanelBottom"
@onready var map_container : MapContainer = $"MapView/SubViewportContainer/SubViewport/MapRoot/MapContainer"
@onready var radio = $"HUD/Radio popup"

func show_modal(content : String, buttonText : String = "Przyjąłem."):
	var modal = find_child("General purpose modal")
	modal.find_child("Label").text = content
	modal.find_child("TextureButton").find_child("Label").text = buttonText
	modal.visible = true
func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_1.tscn")
	var arr = []
	for i in range(3):
		#arr.append(randi_range(2,4))
		arr.append(1)
	for i in range(arr[0]):
		map_container.spawn_event("Police")
	for i in range(arr[1]):
		map_container.spawn_event("Ambulance")
	for i in range(arr[2]):
		map_container.spawn_event("Fire rescue")
	for i in range(randi_range(1, arr[0])):
		map_container.spawn_event("Crime")
	for i in range(randi_range(1, arr[1])):
		map_container.spawn_event("Emergency")
	for i in range(arr[2]):
		map_container.spawn_event("Fire")
func generate_description(event : MapEvent) -> String:
	var desc : String = ""
	if event.type == "Fire":
		desc += "Kategoria: Niekontrolowany ogień w budynku" 
		desc += '\n'
		desc += "Identyfikator budynku: " 
		desc += str(10000 * event.id % 20 + 20000 + 100  * event.id % 30 + 300 + event.id)    
		desc += '\n'
		desc += "Status: Potrzebna pomoc straży pożarnej"
	elif event.type == "Emergency":
		desc += "Kategoria: Wypadek "
		if event.id % 2:
			desc += "samochodowy"
		else:
			desc += "w domu"
		desc += '\n'
		desc += "Wiek poszkodowanego: " 
		desc += str(event.id % 70 + 10)    
		desc += '\n'
		desc += "Status: Potrzebna karetka"
	elif event.type == "Crime":
		desc += "Kategoria: "
		if event.id % 3 == 0:
			desc += "Kradzież z włamaniem"
		if event.id % 3 == 1:
			desc += "Kradzież"
		if event.id % 3 == 2:
			desc += "Napaść"
		desc += "\n"
		desc += "Status: Potrzebna asysta policji"
		
	else:
		print("Wrong event type!")
	return desc
func message( event : MapEvent ) -> void:

	const localization : Dictionary = {
		"Fire" : "Ogień",
		"Police" : "Policja",
		"Fire rescue" : "Straż pożarna",
		"Ambulance" : "Karetka",
		"Emergency" : "Wypadek",
		"Crime" : "Przestępstwo"
	}
	
	if event.type in ["Crime", "Emergency", "Fire"]:
		top_panel.find_child("Label").text = localization[event.type]
		top_panel.find_child("Icon").texture = event.marker.texture_normal
		top_panel.find_child("Desc").text = generate_description(event)
		emergency = event
		if main_event:
			map_container.map_locked = true
			find_child("Message modal").visible = true
	else:
		bottom_panel.find_child("Label").text = localization[event.type]
		bottom_panel.find_child("Icon").texture = event.marker.texture_normal
		unit = event
	if not bottom_panel.find_child("Send").visible and not unit == null and not emergency == null:
		bottom_panel.find_child("Send").visible = true

func _send_unit():
	const unit_to_emergency = {
		"Fire rescue" : "Fire",
		"Police" : "Crime",
		"Ambulance" : "Emergency"
	}
	if emergency.type == unit_to_emergency[unit.type]:
		unit.delete()
		emergency.delete()
		show_modal("Jednostka wysłana")
		unit = null
		emergency = null
		bottom_panel.find_child("Send").visible = false
		top_panel.find_child("Label").text = ""
		top_panel.find_child("Icon").texture = null
		top_panel.find_child("Desc").text = ""
		bottom_panel.find_child("Label").text = ""
		bottom_panel.find_child("Icon").texture = null
	else:
		show_modal("Ups! Źle przydzielona jednostka")
func _main_event():
	if map_container.any_emergencies:
		return
	main_event = true
	show_modal("Uwaga! Nowe zgłoszenie!")
	map_container.spawn_event("Fire", Vector2(200, 818))
	
