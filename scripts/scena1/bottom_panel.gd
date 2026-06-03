extends Panel
class_name Scena1BottomPanel 
@onready var label = $"Label"
@onready var icon = $"Icon"
@onready var description = $"Desc"

func display_event(event : MapEvent):
	const localization : Dictionary = {
		"Fire" : "Ogień",
		"Emergency" : "Wypadek",
		"Crime" : "Przestępstwo"
	}
	label.text = localization[event.type]
	icon.texture = event.marker.texture_normal
	# desc.text = generate_description(event)

func clear():
	label.text = ""
	icon.texture = ""
	description.text = ""
