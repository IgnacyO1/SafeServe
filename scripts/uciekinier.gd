extends CharacterBody2D

var fixed_path = [
	Vector2(-40332, 98595),
Vector2(-40453, 98113),
Vector2(-40664, 97589),
Vector2(-40686, 97154),
Vector2(-40918, 96857),
Vector2(-41200, 96771),
Vector2(-41629, 97064),
Vector2(-41976, 97538),
Vector2(-43014, 98573),
Vector2(-43800, 99408),
Vector2(-44937, 100529),
Vector2(-45995, 101679),
Vector2(-46478, 102118),
Vector2(-47265, 102571),
Vector2(-48234, 103044),
Vector2(-49151, 103342),
Vector2(-50575, 103545),
Vector2(-51564, 103521),
Vector2(-53408, 103396),
Vector2(-55450, 103272),
Vector2(-56387, 102980),
Vector2(-57517, 102580),
Vector2(-58776, 101901),
Vector2(-59555, 101426),
Vector2(-60201, 101217),
Vector2(-61489, 101056),
Vector2(-62323, 100876),
Vector2(-62253, 100265),
Vector2(-62098, 100128),
Vector2(-61526, 99588),
Vector2(-60510, 97912),
Vector2(-60183, 97514),
Vector2(-59125, 96454),
Vector2(-58590, 96034),
Vector2(-57543, 95181),
Vector2(-56634, 93975),
Vector2(-55954, 92885),
Vector2(-55098, 91636),
Vector2(-53417, 89097),
Vector2(-52305, 87449),
Vector2(-50534, 84778),
Vector2(-48606, 81863),
Vector2(-47024, 79524),
Vector2(-45164, 76770),
Vector2(-43750, 74606),
Vector2(-42070, 72104),
Vector2(-40690, 70049),
Vector2(-39702, 68359),
Vector2(-38630, 66138),
Vector2(-37660, 64201),
Vector2(-36409, 62189),
Vector2(-35706, 60844),
Vector2(-35495, 60067),
Vector2(-35488, 58929),
Vector2(-35338, 58013),
Vector2(-34908, 57479),
Vector2(-34471, 57142),
Vector2(-33953, 56744),
Vector2(-33398, 56397),
Vector2(-32923, 56060),
Vector2(-32650, 55657),
Vector2(-32879, 55170),
Vector2(-33370, 54462),
Vector2(-33781, 53898),
Vector2(-34171, 53271),
Vector2(-34487, 52803),
Vector2(-34809, 52339),
Vector2(-34943, 51883),
Vector2(-34506, 51571),
Vector2(-33875, 51117),
Vector2(-33347, 50788),
Vector2(-31105, 49345),
Vector2(-29783, 48509),
Vector2(-29390, 48262),
Vector2(-28402, 47730),
Vector2(-27660, 47360),
Vector2(-26993, 47276),
Vector2(-26357, 47314),
Vector2(-25854, 47512),
Vector2(-25092, 47771),
Vector2(-24122, 48077),
Vector2(-23090, 48458),
Vector2(-22835, 48561),
Vector2(-22378, 48776),
Vector2(-21191, 49226),
Vector2(-19706, 49775),
Vector2(-18607, 50131),
Vector2(-17366, 50535),
Vector2(-16717, 50610),
Vector2(-16407, 50436),
Vector2(-16420, 49261),
Vector2(-16563, 47358),
Vector2(-16644, 45667),
Vector2(-16819, 43055),
Vector2(-16882, 41055),
Vector2(-16873, 40261),
Vector2(-16883, 37260),
Vector2(-16926, 34515),
Vector2(-16973, 32691),
Vector2(-17269, 31575),
Vector2(-18429, 28760),
Vector2(-19607, 25565),
Vector2(-20362, 23705),
Vector2(-21186, 21698),
Vector2(-21855, 19900),
Vector2(-22216, 18791),
Vector2(-22944, 17380),
Vector2(-23812, 17272),
Vector2(-25165, 17710),
Vector2(-27945, 18526),
Vector2(-30246, 19386),
Vector2(-31278, 19487),
Vector2(-32227, 19272),
Vector2(-32967, 18975),
Vector2(-33552, 18541),
Vector2(-34215, 17841),
Vector2(-34854, 17076),
Vector2(-35978, 15694),
Vector2(-36692, 14846),
Vector2(-36867, 14449),
Vector2(-36304, 14021),
Vector2(-36053, 13909),
Vector2(-33605, 12620),
Vector2(-30725, 11154),
Vector2(-28284, 9875),
Vector2(-27377, 9444),
Vector2(-26883, 10269),
Vector2(-25562, 12835),
Vector2(-25111, 13676),
Vector2(-24580, 14672),
Vector2(-24009, 15693),
Vector2(-23560, 16499),
Vector2(-23347, 16933),
Vector2(-23146, 17234),
Vector2(-22217, 16947),
Vector2(-20783, 16391),
Vector2(-19680, 15879),
Vector2(-17048, 14573),
Vector2(-15448, 13731),
Vector2(-14372, 13165),
Vector2(-12947, 12508),
Vector2(-11617, 11808),
Vector2(-10482, 11211),
Vector2(-10216, 10967),
]
var target_index = 0
var speed = 400.0
var map_manager = null
var current_lane_offset = -1.6 
var is_oneway = false
# --- LOGIKA POŚCIGU ---
@export var base_speed: float = 450.0 # Prędkość bazowa (taka jak policja)
var total_path_points: int = 0
var current_progress_index: int = 0
var current_road_points = []

func setup(_unused_points, manager, oneway_status):
	map_manager = manager
	# Używamy na sztywno wpisanej trasy pościgu zamiast tej z argumentu
	current_road_points = fixed_path 
	is_oneway = oneway_status
	current_lane_offset = 0.0
	target_index = 1
	# Ustawiamy go na startowym punkcie trasy pościgu
	global_position = current_road_points[0]
	total_path_points = current_road_points.size()
	
func _ready():
	add_to_group("uciekinier")

func _physics_process(delta):
	if current_road_points.is_empty(): return
	
	# 1. Obliczamy postęp pościgu (0.0 do 1.0)
	var progress = float(current_progress_index) / float(total_path_points)
	
	# 2. Dostosowujemy prędkość wg Twojego planu:
	if progress < 0.1:
		# Pierwsze 10% - ucieka (szybciej niż policja)
		speed = base_speed * 1.2 
	elif progress > 0.9:
		# Ostatnie 10% - daje się złapać (wolniej)
		speed = base_speed * 0.7
	else:
		# Środek pościgu - równa walka
		speed = base_speed

	# Logika ruchu (bez zmian)
	var target_pos = get_offset_point(target_index - 1, target_index)
	var dir = global_position.direction_to(target_pos)
	
	velocity = dir * speed
	
	if velocity.length() > 0:
		var target_angle = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, 10.0 * delta)
	
	move_and_slide()
	
	if global_position.distance_to(target_pos) < 30.0:
		advance_path()

func get_offset_point(from_idx, to_idx):
	var p1 = current_road_points[from_idx]
	var p2 = current_road_points[to_idx]
	var direction = (p2 - p1).normalized()
	var perpendicular = Vector2(direction.y, -direction.x)
	return p2 + perpendicular * (current_lane_offset * map_manager.map_scale)

func advance_path():
	target_index += 1
	current_progress_index += 1 # Zwiększamy licznik postępu
	
	if target_index >= current_road_points.size():
		# Tutaj uciekinier dojechał do końca trasy
		# Możesz tu wywołać koniec misji lub zatrzymanie auta
		speed = 0
		print("Uciekinier dotarł do punktu końcowego!")
