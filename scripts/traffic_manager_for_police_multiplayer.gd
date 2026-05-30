extends Node

@export var uciekinier_scene = preload("res://scenes/PoliceMultiplayer/uciekinier_multiplayer.tscn")

@onready var map_manager = get_node("../MapManager")

var uciekinier = null

func setup_mode(pursuit_active: bool):
	if pursuit_active:
		if is_instance_valid(uciekinier):
			uciekinier.queue_free()
		uciekinier = null

func _process(_delta):
	if not is_instance_valid(uciekinier) and map_manager:
		spawn_boss_car()

func spawn_boss_car():
	if uciekinier_scene == null:
		print("ERROR: uciekinier_scene not loaded")
		return
	
	uciekinier = uciekinier_scene.instantiate()
	add_child(uciekinier)
	uciekinier.setup([], map_manager, false)
	print("SPAWNED: Cyberkrab gotowy do ucieczki!")
