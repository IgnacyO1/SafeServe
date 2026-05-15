extends Node2D
class_name scena_2
@onready var radio = $"HUD/Radio popup"
@onready var map = $Map
	
func _ready() -> void:
	print(map)
