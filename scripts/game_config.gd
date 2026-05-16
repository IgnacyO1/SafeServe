extends Node

const CONFIG_PATH = "user://config.json"

func _ready():
	# Inicjalizuj config jeśli nie istnieje
	if not FileAccess.file_exists(CONFIG_PATH):
		save_level("res://scenes/scena_1.tscn")

func save_level(level_path: String) -> void:
	var config = {
		"current_level": level_path
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
