class_name Emergency
var dialogue_options : Array[DialogueOption]
var coordinates : Vector2

func _init(coordinates_i) -> void:
	coordinates = coordinates_i
	
func add_dialogue_option(option : DialogueOption):
	dialogue_options.append(option)
