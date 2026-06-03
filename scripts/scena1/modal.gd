extends Panel

@onready var label = $"Label"
@onready var button_label = $"TextureButton/Label"
func show_message(content : String, buttonText : String = "Przyjąłem."):
	label.text = content
	button_label.text = buttonText
	visible = true
