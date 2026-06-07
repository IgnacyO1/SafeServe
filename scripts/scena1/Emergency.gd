class_name Emergency
var dialogue_options : Array[DialogueOption]
var coordinates : Vector2
var type : String

func _init(type_i, coordinates_i) -> void:
	type = type_i
	coordinates = coordinates_i
	
func add_dialogue_option(option : DialogueOption):
	dialogue_options.append(option)
