extends Node

@export var uciekinier_scene = preload("res://scenes/PoliceMultiplayer/uciekinier_multiplayer.tscn")
@onready var map_manager = get_node("../MapManager")

var uciekinier = null
var is_active = false
var boss_spawn_point: Vector2 = Vector2(-18006.55, 50855.8)

func get_player_spawn_position() -> Vector2:
	var spawn_point = boss_spawn_point
	if is_instance_valid(uciekinier) and "fixed_path" in uciekinier and not uciekinier.fixed_path.is_empty():
		spawn_point = uciekinier.fixed_path[0]
		if uciekinier.fixed_path.size() > 1:
			var direction = (uciekinier.fixed_path[1] - spawn_point).normalized()
			var perpendicular = Vector2(-direction.y, direction.x)
			return spawn_point + direction * 260.0 + perpendicular * 420.0
	return spawn_point + Vector2(260.0, -420.0)

func setup_mode(pursuit_active: bool):
	# Zabezpieczenie: Tylko serwer dedykowany ma prawo odpalić uciekiniera
	if not multiplayer.is_server(): return 
	
	is_active = pursuit_active
	if pursuit_active and is_instance_valid(uciekinier):
		uciekinier.queue_free()
		uciekinier = null

func _process(_delta):
	if not multiplayer.is_server() or not is_active: return
	
	if not is_instance_valid(uciekinier) and map_manager:
		spawn_boss_car()

func spawn_boss_car():
	if uciekinier_scene == null: return

	var world = get_node("../")
	uciekinier = uciekinier_scene.instantiate()
	uciekinier.name = "CyberkrabBoss" # <- To musi być pierwsze!

	var spawn_point = Vector2(-18006.55, 50855.8)
	if "fixed_path" in uciekinier and not uciekinier.fixed_path.is_empty():
		spawn_point = uciekinier.fixed_path[0]
	boss_spawn_point = spawn_point

	# Ustawiam pozycję przed dodaniem do drzewa, żeby początkowy spawn sieciowy
	# używał dokładnie pierwszego wektora z fixed_path.
	uciekinier.position = spawn_point - world.global_position
	world.add_child(uciekinier) # <- Dopiero teraz wrzucamy do drzewa sieciowego

	uciekinier.setup([], map_manager, false)
	uciekinier.global_position = spawn_point
	print("[SERWER] Spawnowano uciekiniera zsynchronizowanego przez ENet!")
