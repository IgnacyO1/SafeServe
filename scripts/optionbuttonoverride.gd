extends OptionButton


func _ready():
	var popup = get_popup()
	popup.add_theme_stylebox_override('panel', get_theme_stylebox("normal"))
	#popup.panel =  get_theme_stylebox("normal")
