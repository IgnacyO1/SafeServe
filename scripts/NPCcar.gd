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
		# Losujemy nową drogę (unikając zawracania w miejscu, jeśli to możliwe)
		current_road_points = options.pick_random()
		target_index = 1
	else:
		# Ślepa uliczka - zawracamy
		current_road_points.reverse()
		target_index = 1
