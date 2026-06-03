extends Node2D

@export var speed: float = 400.0 # Prędkość tramwaju

var master_distance: float = 0.0
var curve: Curve2D = Curve2D.new()
var current_path_points: PackedVector2Array = PackedVector2Array()

# Zarządzanie strukturą członów
@onready var segments = [$Segment1, $Segment2, $Segment3]

# Ustawienia wózków (w pikselach). Załóżmy, że człon ma 160px długości (8 metrów w skali 20)
# Przesunięcia liczone są od samego przodu (zderzaka pierwszego wagonu)
# Segment 1: wózki na 20px i 140px
# Segment 2: wózki na 180px i 300px (uwzględniając przerwę między wagonami)
# Segment 3: wózki na 340px i 460px
var bogie_presets = [
	{"front": 20.0, "rear": 140.0},
	{"front": 145.0, "rear": 245.0},
	{"front": 250.0, "rear": 375.0}
]

var map_manager = null
var last_node: Vector2

# Specyficzne dla sceny 8 (Boss Fight)
var is_scene8_mode: bool = false
var direction: Vector2 = Vector2.RIGHT
var hit_cooldowns = {}

func _ready():
	curve.bake_interval = 5.0 # Precyzja próbkowania zakrętów (im mniej, tym płynniej)
	for i in range(segments.size()):
		segments[i].setup(bogie_presets[i]["front"], bogie_presets[i]["rear"])

func init_tram(start_node: Vector2, manager):
	map_manager = manager
	last_node = start_node
	
	# Wygeneruj wstępną długą ścieżkę z kilku segmentów torów
	current_path_points.append(start_node)
	for i in range(10): 
		if not extend_path(): break
		
	rebuild_curve()
	# Zacznij z przesunięciem, aby cały tramwaj od razu zespawnował się na torach
	master_distance = 480.0 

func init_straight_line(p_start: Vector2, p_end: Vector2, p_speed: float = 600.0):
	is_scene8_mode = true
	speed = p_speed
	direction = (p_end - p_start).normalized()
	
	current_path_points.append(p_start)
	current_path_points.append(p_end)
	
	rebuild_curve()
	master_distance = 480.0
	
	# Podłączamy sygnały dla Area2D, jeśli istnieją w tej wersji sceny (np. TramBoss)
	for segment in segments:
		segment.add_to_group("tramwaj")
		var area = segment.get_node_or_null("Area2D")
		if area:
			area.body_entered.connect(func(body): _on_segment_body_entered(body, segment))

func _physics_process(delta):
	if current_path_points.size() < 2: return
	
	master_distance += speed * delta
	
	if is_scene8_mode:
		for segment in segments:
			segment.update_position(curve, master_distance)
			
			# Dopasowanie kierunku i zapobieganie obracaniu "do góry nogami"
			var sprite = segment.get_node_or_null("Sprite2D")
			if sprite:
				if direction.x > 0:
					segment.rotation = direction.angle()
					sprite.flip_h = true
				else:
					segment.rotation = direction.angle() + PI
					sprite.flip_h = false
			
		# Obsługa cooldownu kolizji
		for body in hit_cooldowns.keys():
			hit_cooldowns[body] -= delta
			if hit_cooldowns[body] <= 0.0:
				hit_cooldowns.erase(body)
				
		# Usunięcie po przejechaniu całej krzywej
		if master_distance > curve.get_baked_length() + 500.0:
			queue_free()
	else:
		# Jeśli przód tramwaju zbliża się do końca obecnej krzywej, doklej kolejne tory
		if master_distance > curve.get_baked_length() - 600.0:
			if extend_path():
				rebuild_curve()
				
		# Aktualizacja pozycji każdego członu
		for segment in segments:
			segment.update_position(curve, master_distance)



func _on_segment_body_entered(body: Node2D, segment: Node2D):
	if not is_scene8_mode:
		return
	if body in hit_cooldowns:
		return
		
	if body.is_in_group("gracz"):
		hit_cooldowns[body] = 1.5 # 1.5s cooldown
		
		var push_dir = (body.global_position - segment.global_position).normalized()
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.UP if direction.x > 0 else Vector2.DOWN
			
		if body.has_method("apply_knockback"):
			body.apply_knockback(push_dir * 1300.0)
			
		var scena = get_tree().current_scene
		if scena and scena.has_method("_screen_shake"):
			scena._screen_shake(25.0)
			
		if scena and scena.has_method("gracz_trafiony"):
			scena.gracz_trafiony()
			
	elif body.is_in_group("krab"):
		hit_cooldowns[body] = 1.0 # 1s cooldown
		
		var push_dir = (body.global_position - segment.global_position).normalized()
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.UP if direction.x > 0 else Vector2.DOWN
			
		if body.has_method("apply_knockback"):
			body.apply_knockback(push_dir * 1600.0)

func extend_path() -> bool:
	if not map_manager.tram_network.has(last_node):
		return false
		
	var options = map_manager.tram_network[last_node]
	if options.is_empty(): return false
	
	# Losowy wybór następnego segmentu torów na skrzyżowaniu
	var chosen_track = options.pick_random()
	var points = chosen_track["points"]
	
	# Pomijamy pierwszy punkt nowej drogi, bo jest identyczny z last_node
	for i in range(1, points.size()):
		current_path_points.append(points[i])
		
	last_node = points[-1].snapped(Vector2(0.1, 0.1))
	return true

func rebuild_curve():
	# Zapamiętujemy stary upieczony dystans, aby uniknąć teleportacji tramwaju
	curve.clear_points()
	for p in current_path_points:
		curve.add_point(p)
		
	# Optymalizacja pamięci: Usuwamy z tablicy punkty, które tramwaj już dawno minął
	# (Zostawiamy zapas 1000px z tyłu dla ostatniego wagonu)
	if master_distance > 2000.0:
		var cut_dist = master_distance - 1000.0
		var offset_baked = curve.get_closest_offset(curve.sample_baked(cut_dist))
		
		# Znajdź indeks punktu w wektorze do usunięcia
		var points_to_remove = 0
		for i in range(current_path_points.size()):
			if current_path_points[i].distance_to(curve.sample_baked(0)) < offset_baked:
				points_to_remove = i + 1
			else:
				break
				
		if points_to_remove > 0:
			current_path_points = current_path_points.slice(points_to_remove)
			master_distance -= offset_baked
			# Ponowne przebudowanie po oczyszczeniu historii
			curve.clear_points()
			for p in current_path_points:
				curve.add_point(p)
