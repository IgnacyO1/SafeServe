extends CharacterBody2D

var fixed_path = [
	Vector2(-18006.55, 50855.8), Vector2(-17836.64, 50646.7), Vector2(-17577.92, 50525.49), Vector2(-17137.93, 50603.46),
	Vector2(-16752.75, 50616.14), Vector2(-16471.06, 50434.48), Vector2(-16350.36, 50103.26), Vector2(-16398.84, 49223.96),
	Vector2(-16454.39, 48284.79), Vector2(-16538.06, 47232.12), Vector2(-16625.78, 46297.32), Vector2(-16696.8, 44839.03),
	Vector2(-16786.77, 42991.2), Vector2(-16880.63, 41063.46), Vector2(-16888.98, 39467.08), Vector2(-16849.9, 37871.91),
	Vector2(-16882.41, 36337.77), Vector2(-16937.4, 35185.37), Vector2(-16960.15, 33687.79), Vector2(-17006.74, 32735.42),
	Vector2(-17138.01, 32043.14), Vector2(-17375.89, 31326.04), Vector2(-17718.55, 30431.79), Vector2(-18350.46, 28809.39),
	Vector2(-18689.68, 28052.62), Vector2(-19070.96, 27206.56), Vector2(-19577.03, 25906.12), Vector2(-20070.15, 24487.08),
	Vector2(-20463.48, 23418.82), Vector2(-21090.53, 21922.42), Vector2(-21534.33, 20800.38), Vector2(-21885.63, 19801.87),
	Vector2(-22119.45, 19046.74), Vector2(-22600.0, 17887.26), Vector2(-22621.29, 17553.53), Vector2(-22574.57, 17371.28),
	Vector2(-22497.99, 17237.44), Vector2(-22361.04, 17103.19), Vector2(-22216.65, 17010.7), Vector2(-22017.01, 16930.46),
	Vector2(-21509.15, 16746.5), Vector2(-21085.58, 16558.62), Vector2(-20470.2, 16248.93), Vector2(-20013.2, 16003.06),
	Vector2(-19518.64, 15617.63), Vector2(-19054.54, 15334.51), Vector2(-18395.31, 14999.65), Vector2(-16975.8, 14232.25),
	Vector2(-15779.05, 13631.68), Vector2(-14817.19, 13127.13), Vector2(-13720.37, 12597.85), Vector2(-12790.59, 12111.0),
	Vector2(-11892.08, 11656.78), Vector2(-10989.62, 11170.18), Vector2(-10111.69, 10789.28), Vector2(-9322.691, 10400.86)
]

var target_index = 0
var speed = 0.0
var real_speed = 0.0
var map_manager = null
var current_lane_offset = 0.0
var is_oneway = false
var current_road_points = []

# --- USTAWIENIA NIEUCHWYTNOŚCI I POLA WIDZENIA ---
@export var max_allowed_speed: float = 850.0 # Maksymalny limit prędkości uciekiniera, by nie odskoczył za daleko na zakrętach
var reached_end: bool = false

func setup(_unused_points, manager, oneway_status):
	map_manager = manager
	current_road_points = fixed_path 
	is_oneway = oneway_status
	target_index = 1
	global_position = current_road_points[0]
	reached_end = false
	
func _ready():
	add_to_group("uciekinier")

func _physics_process(delta):
	if current_road_points.is_empty(): return
	
	# Jeśli dojechaliśmy do końca – zatrzymujemy auto całkowicie
	if reached_end or target_index >= current_road_points.size():
		speed = 0.0
		velocity = Vector2.ZERO
		move_and_slide()
		real_speed = get_real_velocity().length()
		return

	# Pobieramy instancję oraz aktualną prędkość policji
	var police = get_tree().get_first_node_in_group("police")
	
	if is_instance_valid(police):
		var distance_px = global_position.distance_to(police.global_position)
		var distance_meters = distance_px / 20.0
		
		var police_speed = 0.0
		if "velocity" in police:
			police_speed = police.velocity.length()
		elif police is RigidBody2D:
			police_speed = police.linear_velocity.length()

		# --- DYNAMICZNY RUBBER-BANDING (ZALEŻNY OD DYSTANSU I PRĘDKOŚCI GRACZA) ---
		if distance_meters < 10.0:
			# Gracz jest za blisko (< 10m): Uciekinier gwałtownie ucieka przed zablokowaniem
			speed = police_speed + 250.0
		elif distance_meters > 36.0:
			# Gracz zostaje w tyle (> 35m): Uciekinier zwalnia, by nie spaść z ekranu (ekran to zwykle ok. 15m)
			speed = police_speed * 0.8
		elif distance_meters <25.0:
			# Gracz w bezpiecznym przedziale (5m - 35m): Uciekinier utrzymuje idealnie tempo radiowozu
			speed = police_speed + 50.0
			
		# Zabezpieczenie przed ujemną prędkością oraz absurdalnymi wartościami
		speed = clamp(speed, 50.0, max_allowed_speed)
	else:
		# Brak policji na mapie (fallback)
		speed = 500.0

	# --- LOGIKA RUCHU PO TRASIE ---
	var target_pos = get_offset_point(target_index - 1, target_index)
	var dir = global_position.direction_to(target_pos)
	
	velocity = dir * speed
	
	if velocity.length() > 0:
		var target_angle = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, 10.0 * delta)
	
	move_and_slide()
	real_speed = get_real_velocity().length()
	
	# Warunek przejścia do następnego punktu trasy
	if global_position.distance_to(target_pos) < 60.0:
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
		reached_end = true
		target_index = current_road_points.size() - 1
		speed = 0.0
		print("Uciekinier dotarł do punktu końcowego i wyhamował!")
