extends CharacterBody2D

var current_road_points = []
var previous_road_points = [] # Przechowujemy poprzedni segment, by nie zawracać
var target_index = 0
var speed = 400.0
var map_manager = null
var current_lane_offset = -1.6 
var is_oneway = false



# Zaktualizuj funkcję setup w NPCCar.gd
func setup(start_points, manager, oneway_status):
	map_manager = manager
	current_road_points = start_points
	is_oneway = oneway_status
	current_lane_offset = 0.0 if is_oneway else -1.6
	target_index = 1
	global_position = get_offset_point(0, 1)

func _physics_process(delta):
	if current_road_points.is_empty(): return
	
	var target_pos = get_offset_point(target_index - 1, target_index)
	var dir = global_position.direction_to(target_pos)
	
	velocity = dir * speed
	
	if velocity.length() > 0:
		var target_angle = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, 10.0 * delta)
	
	move_and_slide()
	
	if global_position.distance_to(target_pos) < 15.0:
		advance_path()

func get_offset_point(from_idx, to_idx):
	var p1 = current_road_points[from_idx]
	var p2 = current_road_points[to_idx]
	var direction = (p2 - p1).normalized()
	var perpendicular = Vector2(direction.y, -direction.x)
	return p2 + perpendicular * (current_lane_offset * map_manager.map_scale)

func advance_path():
	target_index += 1
	if target_index >= current_road_points.size():
		find_next_road()

func find_next_road():
	var current_node = current_road_points[-1].snapped(Vector2(0.1, 0.1))
	
	if map_manager.road_network.has(current_node):
		var options = map_manager.road_network[current_node]
		var best_options = []
		
		# Logika anty-zawracania
		var entry_dir = (current_road_points[-1] - current_road_points[-2]).normalized()
		
		for opt in options:
			var exit_dir = (opt.points[1] - opt.points[0]).normalized()
			
			# Jeśli kąt > 150 stopni (dot < -0.85), to uznajemy to za zawracanie
			if exit_dir.dot(entry_dir) > -0.85:
				best_options.append(opt)
		
		var selected_road
		if best_options.size() > 0:
			selected_road = best_options.pick_random()
		else:
			# Ślepa uliczka - jedyna opcja to zawrócić
			selected_road = options.pick_random()
		
		# APLIKUJEMY NOWE DANE
		current_road_points = selected_road.points
		is_oneway = selected_road.oneway
		current_lane_offset = 0.0 if is_oneway else -1.6
		target_index = 1
	else:
		queue_free()
var is_yielding: bool = false
var original_speed: float = 400.0

func yield_to_emergency():
	if is_yielding: return # Już przepuszcza
	
	is_yielding = true
	original_speed = speed # Zapamiętujemy obecną prędkość
	
	# Zjeżdżamy jeszcze mocniej na prawo (korytarz życia)
	current_lane_offset = -6.0 
	
	# Płynne zatrzymanie za pomocą Tweena
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "speed", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Po 5 sekundach auto wraca do ruchu
	get_tree().create_timer(5.0).timeout.connect(resume_driving)

func resume_driving():
	is_yielding = false
	# Powrót do pasów
	current_lane_offset = 0.0 if is_oneway else -1.6
	
	var tween = create_tween()
	# Powolne przyspieszanie do 400.0
	tween.tween_property(self, "speed", 400.0, 2.0).set_trans(Tween.TRANS_LINEAR)
