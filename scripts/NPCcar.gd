extends CharacterBody2D

var current_road_points = []
var target_index = 0
var speed = 400.0
var map_manager = null

func setup(start_road, manager):
	map_manager = manager
	current_road_points = start_road
	target_index = 1
	global_position = current_road_points[0]

func _physics_process(delta):
	if current_road_points.is_empty(): return
	
	var target_pos = current_road_points[target_index]
	var dir = global_position.direction_to(target_pos)
	
	velocity = dir * speed
	look_at(target_pos) # Auto patrzy tam gdzie jedzie
	
	move_and_slide()
	
	if global_position.distance_to(target_pos) < 10.0:
		advance_path()

func advance_path():
	target_index += 1
	# Jeśli dojechaliśmy do końca segmentu (skrzyżowanie)
	if target_index >= current_road_points.size():
		find_next_road()

func find_next_road():
	var current_node = current_road_points[-1].snapped(Vector2(0.1, 0.1))
	
	if map_manager.road_network.has(current_node):
		var options = map_manager.road_network[current_node]
		
		# Logika unikania natychmiastowego zawracania (U-turn)
		# Jeśli mamy więcej niż jedną opcję, odrzućmy tę, która jest powrotem na obecną drogę
		var filtered_options = []
		if options.size() > 1:
			var back_dir = (current_road_points[-2] - current_road_points[-1]).normalized()
			for opt in options:
				var next_dir = (opt[1] - opt[0]).normalized()
				if next_dir.dot(back_dir) < 0.8: # Nie wybieraj dróg o zbyt podobnym kącie do tyłu
					filtered_options.append(opt)
		
		if filtered_options.size() > 0:
			current_road_points = filtered_options.pick_random()
		else:
			current_road_points = options.pick_random()
			
		target_index = 1
	else:
		# PRAWDZIWA ŚLEPA ULICZKA
		# Jeśli to była droga dwukierunkowa, możemy zawrócić. 
		# Ale najbezpieczniej dla logiki agentów (skoro to persistent agents) 
		# jest po prostu go usunąć i zespawnować nowego, by nie psuć ruchu.
		if map_manager.has_method("despawn_agent"): # Jeśli masz dostęp do managera
			# Tutaj możesz wysłać sygnał do TrafficManagera o despawn
			queue_free() 
		else:
			# Ostateczność: zawracanie (może naruszyć oneway, jeśli OSM ma błąd w danych)
			current_road_points.reverse()
			target_index = 1
