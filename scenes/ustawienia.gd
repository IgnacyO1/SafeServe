extends Control

@onready var option_button = $CenterContainer/VBoxContainer/OptionButton
@onready var back_button = $BackButton

func _ready() -> void:
	option_button.add_item("turbo evil crab", 0)
	option_button.add_item("cutie patootie crab", 1)
	
	if GameConfig.crab_mode == "cutie":
		option_button.select(1)
	else:
		option_button.select(0)
		
	option_button.item_selected.connect(_on_option_selected)
	back_button.pressed.connect(_on_back_pressed)

func _on_option_selected(index: int) -> void:
	if index == 0:
		GameConfig.crab_mode = "turbo"
	else:
		GameConfig.crab_mode = "cutie"
	# Save the config so it persists
	GameConfig.save_level(GameConfig.get_last_level())

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
