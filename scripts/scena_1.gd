extends Node
var unit
var emergency 
var top_panel
var bottom_panel
# Called when the node enters the scene tree for the first time.
var map_container : MapContainer 
func _ready() -> void:
	map_container = self.find_child("MapContainer")
	var arr = []
	for i in range(3):
		arr.append(randi_range(2,4))
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
	top_panel = find_child("SidePanelTop")
	bottom_panel = find_child("SidePanelBottom")

func message(event ) -> void:

	const localization : Dictionary = {
		"Fire" : "Ogień",
		"Police" : "Policja",
		"Fire rescue" : "Straż pożarna",
		"Ambulance" : "Karetka",
		"Emergency" : "Wypadek",
		"Crime" : "Przestępstwo"
	}

	print(event.type)
	if event.type in ["Crime", "Emergency", "Fire"]:
		top_panel.find_child("Label").text = localization[event.type]
		top_panel.find_child("Icon").texture = event.marker.texture_normal
		emergency = event
	else:
		bottom_panel.find_child("Label").text = localization[event.type]
		bottom_panel.find_child("Icon").texture = event.marker.texture_normal
		unit = event
	if not bottom_panel.find_child("Send").visible and not unit == null and not emergency == null:
		bottom_panel.find_child("Send").visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _send_unit():
	const unit_to_emergency = {
		"Fire rescue" : "Fire",
		"Police" : "Crime",
		"Ambulance" : "Emergency"
	}
	if emergency.type == unit_to_emergency[unit.type]:
		unit.delete()
		emergency.delete()
		find_child("Success modal").visible = true
		unit = null
		emergency = null
		bottom_panel.find_child("Send").visible = false
		top_panel.find_child("Label").text = ""
		top_panel.find_child("Icon").texture = null
		bottom_panel.find_child("Label").text = ""
		bottom_panel.find_child("Icon").texture = null
		print(map_container.any_emergencies)
	else:
		find_child("Fail modal").visible = true
		
func _main_event():
	if map_container.any_emergencies:
		return
	find_child("New emergency modal").visible = true
	
	map_container.spawn_event("Fire")
