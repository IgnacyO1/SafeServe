extends Panel
@onready var container = $"ScrollContainer/VBoxContainer"
var children_count : int = 0
var button_queue : Array[Button]
var buttons : Array[Button]
@onready var bottom_panel = get_tree().current_scene.bottom_panel
var root

func spawn_button(text : String, icon : Texture2D) -> Button:
	var button = Button.new()
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.icon = icon
	button.text = "Wyślij"
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	var pressed_stylebox = StyleBoxEmpty.new()
	pressed_stylebox.content_margin_left = 14
	pressed_stylebox.content_margin_right = 6
	pressed_stylebox.content_margin_top = 8
	pressed_stylebox.content_margin_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed_stylebox)
	button.add_theme_font_size_override("font_size", 14)
	return button
	
func spawn_unit(type: String, people_count : int, busy : bool):
	const textures_map : Dictionary[String,Texture2D] = {
		"Fire" : preload("res://assets/graphics/scena_1/fire_truck.svg"),
		"Crime" : preload("res://assets/graphics/scena_1/police.svg"),
	}
	var icon_texture : Texture2D = textures_map[type]
	var item_size = Vector2(size.x, 128)
	var reg_id : String = "KR "
	for i in range(5):
		reg_id += String.chr(65 + randi_range(0, 25))
	
	var icon = Sprite2D.new()
	icon.name = type
	icon.texture = icon_texture
	icon.scale = Vector2(2, 2)
	icon.position = icon_texture.get_size()
	const button_width = 160
	
	var label = RichTextLabel.new()
	label.text = "Nr rejestracyjny: " + reg_id + '\n'  + "Ilość osób: "+ str(people_count) 
	label.bbcode_enabled = true
	label.custom_minimum_size = Vector2(item_size.x - icon_texture.get_height() * 2 - button_width, item_size.y)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.name = "rtl"
	if busy:
		label.text += "\n[color=red]Zajęty[/color]"
	else:
		label.text += "\n[color=green]Wolny[/color]"
	label.position = Vector2(icon_texture.get_width() * 2, 0)
	
	var button = spawn_button("Wyślij", preload("res://assets/graphics/scena_1/Button.png"))
	if busy:
		button.disabled = true
		#button.icon = preload("res://assets/graphics/scena_1/Button disabled 2.png")
	button.name = "btn"
	button.size = Vector2(button_width, item_size.y)
	button.position = Vector2(item_size.x - button_width, 0)
	buttons.append(button)
	
	var control = Control.new()
	control.add_child(icon)
	control.add_child(label)
	control.add_child(button)
	control.custom_minimum_size = item_size
	#control.position.y = 128 * children_count
	button.pressed.connect(func(): send_unit(control))
	
	
	container.add_child(control)
	children_count += 1
		
func _ready() -> void:
	spawn_unit("Fire", 2, true)
	spawn_unit("Fire", 2, false)
	spawn_unit("Fire", 3, true)
	spawn_unit("Fire", 5, true)
	spawn_unit("Crime", 2, true)
	spawn_unit("Crime", 3, true)
	spawn_unit("Crime", 3, false)
	disable_buttons()
	root = get_tree().current_scene
	
	
func send_unit(unit : Control):
	var type
	for c in unit.get_children():
		if c is Sprite2D:
			type = c.name
	print(type)
	print(root.emergency.type)
	if type != root.emergency.type:
		root.modal.show_message("Ups! Zły rodzaj jednostki!")
		return
	unit.get_node_or_null("btn").disabled = true
	unit.get_node("rtl").text = unit.get_node("rtl").text.replace("[color=green]Wolny[/color]", "[color=red]Zajęty[/color]" )

	root.bottom_panel.clear()
	root.bottom_panel.call_in_progress = false
	root.modal.show_message("Jednostka wysłana!")
	root.map_container.clear()
	disable_buttons()

func end_call():
	enable_buttons()

func disable_buttons():
	for button in buttons:
		if button.disabled == false:
			button.disabled = true
			button_queue.append(button)

func enable_buttons():
	for child in button_queue:
		child.disabled = false
	if button_queue.size() == 0:
		return false
	button_queue.clear()
	return true
