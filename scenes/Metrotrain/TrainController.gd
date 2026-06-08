extends Node2D

@export var speed: float = 400.0

var master_distance: float = 0.0
var curve: Curve2D = Curve2D.new()
var current_path_points: PackedVector2Array = PackedVector2Array()

@onready var segments = [$Segment1, $Segment2, $Segment3, $Segment4, $Segment5]

var bogie_presets = [
	{"front": 10.0, "rear": 180.0},
	{"front": 200.0, "rear": 350.0},
	{"front": 370.0, "rear": 520.0},
	{"front": 540.0, "rear": 690.0},
	{"front": 710.0, "rear": 880.0}
]

var hit_cooldowns = {}

func _ready():
	curve.bake_interval = 5.0
	for i in range(segments.size()):
		segments[i].setup(bogie_presets[i]["front"], bogie_presets[i]["rear"])

func init_from_path2d(path_node: Path2D, p_speed: float = 100.0):
	speed = p_speed
	current_path_points.clear()
	
	for i in range(path_node.curve.point_count):
		var local_pos = path_node.curve.get_point_position(i)
		var global_pos = path_node.to_global(local_pos)
		current_path_points.append(global_pos)
		
	rebuild_curve()
	master_distance = 480.0
	
	for segment in segments:
		segment.add_to_group("tramwaj")
		_prepare_hit_area(segment)

func _physics_process(delta):
	if current_path_points.size() < 2: 
		return
	
	master_distance += speed * delta
	
	for segment in segments:
		segment.update_position(curve, master_distance)
		
	# Obsługa cooldownu kolizji
	for body in hit_cooldowns.keys():
		hit_cooldowns[body] -= delta
		if hit_cooldowns[body] <= 0.0:
			hit_cooldowns.erase(body)
			
	if master_distance > curve.get_baked_length() + 600.0:
		queue_free()

func _prepare_hit_area(segment: Node2D):
	var area = segment.get_node_or_null("HitArea")
	if not area:
		area = Area2D.new()
		area.name = "HitArea"
		area.monitoring = true
		area.monitorable = true
		area.collision_layer = 1
		area.collision_mask = 1
		segment.add_child(area)

	var source_shape = segment.get_node_or_null("CollisionShape2D")
	var existing_shape = area.get_node_or_null("CollisionShape2D")
	if source_shape and not existing_shape:
		existing_shape = CollisionShape2D.new()
		existing_shape.shape = source_shape.shape
		existing_shape.position = source_shape.position
		existing_shape.rotation = source_shape.rotation
		existing_shape.scale = source_shape.scale
		area.add_child(existing_shape)

	if area.body_entered.is_connected(_on_segment_hit):
		area.body_entered.disconnect(_on_segment_hit)
	area.body_entered.connect(_on_segment_hit)
	if area.area_entered.is_connected(_on_segment_hit):
		area.area_entered.disconnect(_on_segment_hit)
	area.area_entered.connect(_on_segment_hit)

func _on_segment_hit(node: Node2D):
	if not is_instance_valid(node):
		return
	if node in hit_cooldowns:
		return
	
	if node.is_in_group("gracz"):
		hit_cooldowns[node] = 3.0
		
		# Szukamy skryptu poziomu, wchodząc w górę drzewa węzłów
		var parent_node = self.get_parent()
		var znalazlem_skrypt = false
		
		while parent_node != null:
			if parent_node.has_method("gracz_trafiony"):
				parent_node.gracz_trafiony()
				znalazlem_skrypt = true
				break
			parent_node = parent_node.get_parent()
			
		# Koło ratunkowe: jeśli pociąg nie znalazł rodzica, próbuje starej metody
		if not znalazlem_skrypt:
			var scena = get_tree().current_scene
			if scena and scena.has_method("gracz_trafiony"):
				scena.gracz_trafiony()

func rebuild_curve():
	curve.clear_points()
	for p in current_path_points:
		curve.add_point(p)
