extends Node

const CONFIG_PATH = "user://config.json"

var crab_mode: String = "turbo" # "turbo" or "cutie"
var multiplayer_loser: bool = false # Czy gracz przegrał wyścig w multiplayerze

func _ready():
	_load_config()
	if not FileAccess.file_exists(CONFIG_PATH):
		save_level("res://scenes/scena_1.tscn")

func _load_config():
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				var data = json.get_data()
				if data.has("crab_mode"):
					crab_mode = data["crab_mode"]

func _input(event):
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "Scena8":
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			crab_mode = "cutie"
			save_level(get_last_level())
		elif event.keycode == KEY_F2:
			crab_mode = "turbo"
			save_level(get_last_level())

func save_level(level_path: String) -> void:
	var config = {
		"current_level": level_path,
		"crab_mode": crab_mode
	}
	var json = JSON.stringify(config)
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json)
	else:
		push_error("Nie można zapisać config.json: ", FileAccess.get_open_error())

func get_last_level() -> String:
	if not FileAccess.file_exists(CONFIG_PATH):
		return "res://scenes/scena_1.tscn"
	
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			return data.get("current_level", "res://scenes/scena_1.tscn")
	
	return "res://scenes/scena_1.tscn"
