extends Node2D

@export var speed: float = 350.0 # Prędkość tramwaju

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

func _physics_process(delta):
	if current_path_points.size() < 2: return
	
	master_distance += speed * delta
	
	# Jeśli przód tramwaju zbliża się do końca obecnej krzywej, doklej kolejne tory
	if master_distance > curve.get_baked_length() - 600.0:
		if extend_path():
			rebuild_curve()
			
	# Aktualizacja pozycji każdego członu
	for segment in segments:
		segment.update_position(curve, master_distance)

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
				points_to_remove = i
			else:
				break
				
		if points_to_remove > 0:
			current_path_points = current_path_points.slice(points_to_remove)
			master_distance -= offset_baked
			# Ponowne przebudowanie po oczyszczeniu historii
			curve.clear_points()
			for p in current_path_points:
				curve.add_point(p)
