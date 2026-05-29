extends CharacterBody2D

# --- BAZA WARIANTÓW SAMOCHODÓW ---
# Definiujemy tekstury dla różnych marek/typów aut
const CAR_VARIANTS = [
	"res://assets/cars/car1.png",
	"res://assets/cars/car2.png",
	"res://assets/cars/car3.png",
	"res://assets/cars/car4.png",
	"res://assets/cars/car5.png",
	"res://assets/cars/car6.png",
	"res://assets/cars/car7.png",
	"res://assets/cars/car8.png"
]

var current_road_points = []
var target_index = 0
var speed = 400.0
var map_manager = null
var current_lane_offset = -1.6 
var is_oneway = false

var is_yielding: bool = false
var original_speed: float = 400.0

@onready var sprite = $Sprite2D # <--- Łapiemy nasz jedyny Sprite2D

func _ready():
	choose_random_variant()

func choose_random_variant():
	if CAR_VARIANTS.is_empty(): return
	
	# 1. Losujemy losową teksturę z listy
	var random_texture_path = CAR_VARIANTS.pick_random()
	sprite.texture = load(random_texture_path)
	
	# 2. Opcjonalnie: Dodajemy wariancję osiągów na podstawie wylosowanego typu!
	if "truck" in random_texture_path:
		original_speed = randf_range(280.0, 320.0) # Ciężarówki są wolniejsze
	elif "suv" in random_texture_path:
		original_speed = randf_range(360.0, 410.0)
	else:
		original_speed = randf_range(400.0, 460.0) # Sedany i hatchbacki
		
	speed = original_speed

func setup(start_points, manager, oneway_status):
	map_manager = manager
	current_road_points = start_points
	is_oneway = oneway_status
	current_lane_offset = 0.0 if is_oneway else -1.6
	target_index = 1
	global_position = get_offset_point(0, 1)

func _physics_process(delta):
	if current_road_points.is_empty(): return
	
	# KLUCZOWA ZMIANA: Przeliczamy target_pos w każdej klatce.
	# Dzięki temu zmiana current_lane_offset zadziała natychmiast!
	var target_pos = get_offset_point(target_index - 1, target_index)
	var dir = global_position.direction_to(target_pos)
	
	velocity = dir * speed
	
	if velocity.length() > 0:
		var target_angle = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, 10.0 * delta)
	
	move_and_slide()
	
	# Jeśli jesteśmy blisko punktu, idziemy do następnego
	if global_position.distance_to(target_pos) < 20.0:
		advance_path()

func get_offset_point(from_idx, to_idx):
	var p1 = current_road_points[from_idx]
	var p2 = current_road_points[to_idx]
	var direction = (p2 - p1).normalized()
	# Wektor prostopadły
	var perpendicular = Vector2(direction.y, -direction.x)
	# Zwracamy punkt przesunięty o aktualny offset
	return p2 + perpendicular * (current_lane_offset * map_manager.map_scale)

func advance_path():
	target_index += 1
	if target_index >= current_road_points.size():
		find_next_road()

func find_next_road():
	var current_node = current_road_points[-1].snapped(Vector2(0.1, 0.1))
	if map_manager.road_network.has(current_node):
		var options = map_manager.road_network[current_node]
		
		# Oblicz kierunek wejściowy
		var entry_dir = (current_road_points[-1] - current_road_points[-2]).normalized()
		
		var option_weights = []
		for opt in options:
			var exit_dir = (opt.points[1] - opt.points[0]).normalized()
			
			# Kąt skrętu w radianach
			var x = entry_dir.angle_to(exit_dir)
			
			# Wzór: f(x) = (sin(x + PI/2) + 1) * 1.5
			var f_x = (sin(x + 0.5 * PI) + 1.0) * (0.5 + 1.0)
			
			# U-turn kara (jeśli jedzie z powrotem na tę samą drogę)
			if exit_dir.dot(entry_dir) < -0.85:
				f_x -= 10.0
				
			option_weights.append(f_x)
			
		# Obliczanie Softmax dla wyboru drogi
		var exps = []
		var sum_exps = 0.0
		for w in option_weights:
			var e = exp(w)
			exps.append(e)
			sum_exps += e
			
		var r = randf() * sum_exps
		var cumulative = 0.0
		var selected_road = options[0]
		
		for i in range(options.size()):
			cumulative += exps[i]
			if r <= cumulative:
				selected_road = options[i]
				break
		
		current_road_points = selected_road.points
		is_oneway = selected_road.oneway
		# Jeśli nie uciekamy przed syreną, ustawiamy standardowy offset
		if not is_yielding:
			current_lane_offset = 0.0 if is_oneway else -1.6
		target_index = 1
	else:
		queue_free()

# Funkcje RATUNKOWE

func yield_to_emergency():
	print("WYWOŁUJE SIĘ FUNKCJA")
	if is_yielding: return 
	
	is_yielding = true
	original_speed = 400.0
	
	# Bardzo duży offset, żeby auto zjechało na samą krawędź (lub poza nią)
	# Tween animuje offset, więc auto płynnie "skręca" na pobocze
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "current_lane_offset", -6.0, 1.0) # Zjazd w 1 sekunde
	tween.tween_property(self, "speed", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	get_tree().create_timer(5.0).timeout.connect(resume_driving)

func resume_driving():
	is_yielding = false
	var target_offset = 0.0 if is_oneway else -1.6
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "current_lane_offset", target_offset, 2.0)
	tween.tween_property(self, "speed", original_speed, 2.0)
