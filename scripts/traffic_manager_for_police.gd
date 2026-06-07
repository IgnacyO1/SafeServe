extends Node

@export var uciekinier_scene = preload("res://scenes/uciekinier.tscn")

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

	var world = get_parent()
	uciekinier = uciekinier_scene.instantiate()

	var spawn_point = Vector2.ZERO
	if "fixed_path" in uciekinier and not uciekinier.fixed_path.is_empty():
		spawn_point = uciekinier.fixed_path[0]

	uciekinier.position = spawn_point - world.global_position
	add_child(uciekinier)
	uciekinier.setup([], map_manager, false)
	uciekinier.global_position = spawn_point
	print("SPAWNED: Cyberkrab gotowy do ucieczki!")
