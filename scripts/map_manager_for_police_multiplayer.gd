extends Node2D

# Konfiguracja
var chunk_size_meters = 200.0
var map_scale = 20.0
var load_radius = 1
var chunk_path = "res://data/map_chunks/"

@export var night_mode: bool = false
var bg_color_day = Color(0.22, 0.32, 0.22)
var bg_color_night = Color(0.03, 0.06, 0.14)
var road_color_day = Color.WHITE
var road_color_night = Color(0.35, 0.45, 0.55)
var sidewalk_color_day = Color(0.8, 0.8, 0.8)
var sidewalk_color_night = Color(0.4, 0.5, 0.6)
var building_color_day = Color(0.3, 0.3, 0.35)
var building_color_night = Color(0.14, 0.16, 0.22)
var building_outline_day = Color(0.1, 0.1, 0.1)
var building_outline_night = Color(0.06, 0.08, 0.14)
var tree_color_night = Color(0.25, 0.35, 0.24)
var water_color_night = Color(0.09, 0.16, 0.30)
var road_arrow_color_night = Color(0.6, 0.8, 0.92, 0.75)

var last_update_pos = Vector2.ZERO
var update_threshold = 200.0

@onready var chunk_size_px = chunk_size_meters * map_scale

# Zasoby
@onready var grass_tex = preload("res://assets/graphics/tileable_grass_00.png")
@onready var asphalt_tex = preload("res://assets/graphics/01tizeta_asphalts.png")
@onready var tree_tex = preload("res://assets/graphics/tree_top.png")
@onready var sidewalk_tex = preload("res://assets/graphics/pavement_2.png")
@onready var water_tex = preload("res://assets/graphics/water.tres")

var loaded_chunks = {}
var road_network = {}
var chunk_load_queue = []
var chunk_roads = {} # c_id -> Array of {"start_node": Vector2, "road_data": Dictionary}
var major_nodes = []

@export var player_path: NodePath
# Bezpieczne pobranie gracza — nie wywołuj `get_node` dla pustej ścieżki
@onready var player = get_node(player_path)

# NOWE: Funkcja inicjalizująca, wywoływana przez scenę trasy
func initialize_map(start_pos: Vector2):
	if player:
		player.global_position = start_pos
		last_update_pos = start_pos
	
	# Czyścimy stare dane, jeśli to kolejny wyścig
	for c in loaded_chunks.values(): c.queue_free()
	loaded_chunks.clear()
	chunk_load_queue.clear()
	road_network.clear()
	chunk_roads.clear()
	major_nodes.clear()
	
	update_chunks()

func _process(_delta):
	if player:
		if player.global_position.distance_to(last_update_pos) > update_threshold:
			update_chunks()
			last_update_pos = player.global_position

		if chunk_load_queue.size() > 0:
			var next_chunk = chunk_load_queue.pop_front()
			load_chunk_from_json(next_chunk)
func update_chunks():
	var p_x = int(floor(player.global_position.x / chunk_size_px))
	var p_y = int(floor(player.global_position.y / chunk_size_px))
	
	var needed_ids = []
	for x in range(p_x - load_radius, p_x + load_radius + 1):
		for y in range(p_y - load_radius, p_y + load_radius + 1):
			needed_ids.append(str(x) + "_" + str(y))
	
	# Usuwanie starych chunków
	var removed_any = false
	for c_id in loaded_chunks.keys():
		if not c_id in needed_ids:
			loaded_chunks[c_id].queue_free()
			loaded_chunks.erase(c_id)
			unload_chunk_roads(c_id)
			removed_any = true
			
	if removed_any:
		rebuild_major_nodes()
			
	# Zamiast ładować od razu, dodajemy do kolejki
	for c_id in needed_ids:
		if not loaded_chunks.has(c_id) and not c_id in chunk_load_queue:
			chunk_load_queue.append(c_id)

func load_chunk_from_json(c_id):
	var file_name = chunk_path + "chunk_" + c_id + ".json"
	if not FileAccess.file_exists(file_name): return
		
	var file = FileAccess.open(file_name, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data == null: return

	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_" + c_id
	add_child(chunk_node)
	loaded_chunks[c_id] = chunk_node
	
	# TŁO CHUNKA (Trawa)
	var coords = c_id.split("_")
	var cx = int(coords[0])
	var cy = int(coords[1])
	
	# Zmień te linie w sekcji TŁO CHUNKA
	var bg = Sprite2D.new()
	bg.texture = grass_tex
	bg.centered = false
	bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED # To włącza kafelkowanie
	bg.region_enabled = true
	# Region musi być w pikselach (rozmiar chunka), wtedy tekstura wypełni go kafelkami
	bg.region_rect = Rect2(0, 0, chunk_size_px, chunk_size_px)
	bg.position = Vector2(cx * chunk_size_px, cy * chunk_size_px)
	bg.z_index = -10
	if night_mode:
		bg.modulate = Color(0.35, 0.45, 0.5, 1.0)
	else:
		bg.modulate = Color(1, 1, 1, 1)
	chunk_node.add_child(bg)
	
	for feature in data:
		var props = feature.get("props", {})
		var highway_type = props.get("highway", "")
		
		var drivable_roads = ["primary", "secondary", "tertiary", "residential", "unclassified", "service", "motorway", "trunk"]
		
		if feature["type"] != "building" and highway_type in drivable_roads:
			var is_oneway = props.get("oneway") == "yes"
			# POPRAWKA: Przekazujemy props jako osobny parametr, zachowując c_id na końcu
			register_road_in_network(feature["geometry"], is_oneway, props, c_id)
		
		# TUTAJ: Dodajemy c_id jako trzeci parametr
		spawn_feature(feature, chunk_node, c_id)
		
	rebuild_major_nodes()

func register_road_in_network(coords, is_oneway, props: Dictionary, c_id: String):
	var points = []
	for p in coords:
		points.append(Vector2(p[0] * map_scale, p[1] * map_scale))
	
	if points.size() < 2: return

	var start_node = points[0].snapped(Vector2(0.1, 0.1))
	var end_node = points[-1].snapped(Vector2(0.1, 0.1))
	
	var highway_type = props.get("highway", "")
	var major_roads = ["motorway", "trunk", "primary", "secondary", "tertiary"]
	var is_major_road = highway_type in major_roads

	# Bezpieczne i bezbłędne pobranie szerokości
	var calculated_width = calculate_road_width(props)

	if not road_network.has(start_node): road_network[start_node] = []
	
	var road_data = {
		"points": points,
		"oneway": is_oneway,
		"is_major": is_major_road,
		"width": calculated_width # Dodane na potrzeby gracza, NPC to ignorują
	}
	road_network[start_node].append(road_data)
	
	if not chunk_roads.has(c_id):
		chunk_roads[c_id] = []
	chunk_roads[c_id].append({"start_node": start_node, "road_data": road_data})
	
	if not is_oneway:
		var reversed_points = points.duplicate()
		reversed_points.reverse()
		if not road_network.has(end_node): road_network[end_node] = []
		var rev_road_data = {
			"points": reversed_points,
			"oneway": false,
			"is_major": is_major_road,
			"width": calculated_width
		}
		road_network[end_node].append(rev_road_data)
		chunk_roads[c_id].append({"start_node": end_node, "road_data": rev_road_data})

func unload_chunk_roads(c_id: String):
	if chunk_roads.has(c_id):
		for entry in chunk_roads[c_id]:
			var start_node = entry.start_node
			var road_data = entry.road_data
			if road_network.has(start_node):
				road_network[start_node].erase(road_data)
				if road_network[start_node].is_empty():
					road_network.erase(start_node)
		chunk_roads.erase(c_id)

func rebuild_major_nodes():
	major_nodes.clear()
	for node in road_network.keys():
		for road_data in road_network[node]:
			if road_data.get("is_major", false):
				major_nodes.append(node)
				break

func spawn_feature(feature, parent, c_id):
	var props = feature["props"]
	var type = feature["type"]
	
	# Punkty (Drzewa)
	if props.get("natural") == "tree" or type == "tree":
		var pos = Vector2(feature["geometry"][0][0] * map_scale, feature["geometry"][0][1] * map_scale)
		create_tree(pos, parent)
		return

	var points = PackedVector2Array()
	for p in feature["geometry"]:
		points.append(Vector2(p[0] * map_scale, p[1] * map_scale))

	if props.get("railway") == "platform" or props.has("public_transport") or props.get("highway") == "platform":
		create_platform(points, parent, props)
		return

	# Woda
	if props.has("water") or props.has("waterway") or props.get("natural") == "water":
		create_water(points, parent, props)
		return

	# Tory 
	if props.has("railway") and props.get("railway") in ["tram", "rail", "subway"]:
		create_railway(points, parent, props)
		return

	# Budynki i Drogi
	if type == "building" or props.has("building"):
		create_building(points, parent)
	else:
		create_road(points, parent, props)
	

func create_building(points, parent):
	# Podstawowa walidacja danych z OSM
	if points.size() < 3:
		return
	
	# Czyszczenie geometrii
	# OSM czasem duplikuje punkty lub ma "brudne" dane. 
	# offset_polygon(points, 0) to szybki sposób na naprawienie struktury poligonu.
	var cleaned_polygons = Geometry2D.offset_polygon(points, 0.0)
	if cleaned_polygons.size() == 0:
		return
	var clean_points = cleaned_polygons[0]

	# Rozwiązanie problemu "duchów" - Dekompozycja
	# Dzielimy budynek (który może być wklęsły, np. w kształcie L) 
	# na kilka mniejszych poligonów wypukłych (convex), które silnik fizyki rozumie idealnie.
	var convex_polygons = []
	if is_polygon_convex_custom(clean_points):
		convex_polygons.append(clean_points)
	else:
		convex_polygons = Geometry2D.decompose_polygon_in_convex(clean_points)
	
	var body = StaticBody2D.new()
	body.collision_layer = 1 # Warstwa ŚWIAT
	body.collision_mask = 0  # Budynek sam nie musi nic wykrywać
	
	# WIZUALIZACJA (Dach)
	var visual = Polygon2D.new()
	visual.polygon = clean_points
	visual.color = building_color_night if night_mode else building_color_day
	visual.z_index = 2
	body.add_child(visual)

	# WIZUALIZACJA (Cień)
	var shadow = Polygon2D.new()
	shadow.polygon = clean_points
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.position = Vector2(5, 5) # Lekkie przesunięcie dla efektu 3D
	shadow.z_index = 1
	body.add_child(shadow)

	# WIZUALIZACJA (Obrys)
	var outline = Line2D.new()
	var opoints = clean_points
	opoints.append(clean_points[0]) # Zamknięcie pętli obrysu
	outline.points = opoints
	outline.width = 2.0
	outline.default_color = building_outline_night if night_mode else building_outline_day
	outline.z_index = 3
	body.add_child(outline)

	# KOLIZJA (Fizyka)
	# Dodajemy osobny kształt kolizji dla każdego wypukłego fragmentu budynku
	for poly in convex_polygons:
		var collision = CollisionPolygon2D.new()
		collision.polygon = poly
		# BUILD_SOLIDS zapewnia, że całe wnętrze budynku jest "twarde"
		collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		body.add_child(collision)
		
	parent.add_child(body)

func create_road(points, parent, props: Dictionary):
	var road = Line2D.new()
	road.points = points
	
	var highway = props.get("highway", "")
	var is_sidewalk = highway in ["footway", "path", "pedestrian", "cycleway"]
	var is_oneway = props.get("oneway") == "yes"
	
	# Korzystamy z nowej, wspólnej funkcji:
	road.width = calculate_road_width(props)
	
	if is_sidewalk:
		road.texture = sidewalk_tex
		road.z_index = -3
		road.default_color = sidewalk_color_night if night_mode else sidewalk_color_day
	else:
		road.texture = asphalt_tex
		road.z_index = -2
		road.default_color = road_color_night if night_mode else road_color_day
		if night_mode:
			road.modulate = Color(0.65, 0.75, 0.85, 1.0)
	
	road.texture_mode = Line2D.LINE_TEXTURE_TILE
	road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	road.begin_cap_mode = Line2D.LINE_CAP_ROUND
	road.end_cap_mode = Line2D.LINE_CAP_ROUND
	road.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(road)
	
	if is_oneway and points.size() >= 2:
		render_oneway_arrows(points, parent)

func render_oneway_arrows(points, parent):
	var arrow_spacing = 40.0 * map_scale # Strzałka co 40 metrów
	var arrow_size = 2.0 * map_scale     # Rozmiar ramion strzałki
	
	var arrow_points = PackedVector2Array()
	
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i+1]
		var dir = (p2 - p1).normalized()
		var segment_len = p1.distance_to(p2)
		
		var d = arrow_spacing / 2.0 # Zacznij kawałek od początku segmentu
		while d < segment_len:
			var pos = p1 + dir * d
			
			# Obliczamy ramiona strzałki
			var left_arm = pos - dir * arrow_size + dir.rotated(PI/2) * (arrow_size * 0.5)
			var right_arm = pos - dir * arrow_size + dir.rotated(-PI/2) * (arrow_size * 0.5)
			
			arrow_points.append(left_arm)
			arrow_points.append(pos)
			arrow_points.append(right_arm)
			arrow_points.append(pos)
			
			d += arrow_spacing

	if arrow_points.size() > 0:
		var arrows = OnewayArrows.new()
		arrows.arrow_points = arrow_points
		arrows.width = 0.5 * map_scale
		arrows.z_index = -1
		if night_mode:
			arrows.color = road_arrow_color_night
		parent.add_child(arrows)
func create_tree(pos, parent):
	var tree_node = StaticBody2D.new()
	tree_node.collision_layer = 1
	tree_node.collision_mask = 0
	tree_node.position = pos
	
	# Cień drzewa (lekko przesunięte czarne kółko lub kopia sprita)
	var shadow = Sprite2D.new()
	shadow.texture = tree_tex
	shadow.modulate = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(3, 3)
	shadow.scale = Vector2(0.1, 0.1) * map_scale # Dopasuj skalę do mapy
	shadow.z_index = 1
	
	# Korona drzewa
	var visual = Sprite2D.new()
	visual.texture = tree_tex
	visual.modulate = tree_color_night if night_mode else Color(1, 1, 1, 1)
	visual.scale = Vector2(0.1, 0.1) * map_scale
	visual.z_index = 4 # Wyżej niż dachy budynków (opcjonalnie)

	# Kolizja (okrągła, żeby auto mogło się obetrzeć o drzewo)
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 0.4 * map_scale # Promień pnia/kolizji
	col.shape = circle

	tree_node.add_child(shadow)
	tree_node.add_child(visual)
	tree_node.add_child(col)
	parent.add_child(tree_node)

func create_water(points, parent, props):
	# Podstawowa walidacja
	if points.size() < 3: 
		return
	
	# Sprawdzamy, czy to jest zamknięty obszar (Poligon)
	# Sprawdzamy czy pierwszy i ostatni punkt są blisko siebie
	var is_polygon = points[0].distance_to(points[-1]) < 0.1
	
	if not is_polygon:
		# Jeśli to linia (rzeczka/kanał), a nie chcemy jej rysować - kończymy funkcję tutaj
		return

	# Jeśli doszliśmy tutaj, znaczy że mamy obszar (np. Wisłę)
	var water_node = Polygon2D.new()
	water_node.polygon = points
	
	# Ustawienia tekstury (AnimatedTexture)
	water_node.texture = water_tex
	water_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	water_node.texture_scale = Vector2(2.0, 2.0)
	water_node.modulate = water_color_night if night_mode else Color(1, 1, 1, 1)
	
	# Naprawa ewentualnych błędów geometrii (częste w OSM przy wodzie)
	# offset_polygon z wartością 0 naprawia strukturę punktów
	var cleaned = Geometry2D.offset_polygon(points, 0.0)
	if cleaned.size() > 0:
		water_node.polygon = cleaned[0]
	
	parent.add_child(water_node)

func create_railway(points, parent, props):
	var is_tram = props.get("railway") == "tram"
	var gauge = 1.435 * map_scale # Standardowy rozstaw szyn (w skali)
	
	# Rysujemy dwie szyny (jako dwa Line2D przesunięte o offset)
	for offset in [-gauge/2, gauge/2]:
			var rail = Line2D.new()
			var offset_points = Geometry2D.offset_polyline(points, offset, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
			if offset_points.size() > 0:
				rail.points = offset_points[0]
				rail.width = 0.15 * map_scale
				rail.default_color = Color(0.2, 0.2, 0.2)
				rail.z_index = -1
				# KLUCZ: Brak zaokrągleń na końcach szyn
				rail.begin_cap_mode = Line2D.LINE_CAP_NONE
				rail.end_cap_mode = Line2D.LINE_CAP_NONE
				parent.add_child(rail)

	# DODATEK: Podkłady dla kolei (nie dla tramwajów, chyba że chcesz)
	if not is_tram:
		render_railway_sleepers(points, parent)

func render_railway_sleepers(points, parent):
	var sleeper_spacing = 0.6 * map_scale # Podkłady co ok. 60cm
	var sleeper_width = 2.4 * map_scale   # Szerokość podkładu
	
	var sleeper_points = PackedVector2Array()
	
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i+1]
		var dir = (p2 - p1).normalized()
		var perp = Vector2(-dir.y, dir.x) # Wektor prostopadły
		var segment_len = p1.distance_to(p2)
		
		var d = 0.0
		while d < segment_len:
			var pos = p1 + dir * d
			var s_p1 = pos + perp * (sleeper_width / 2)
			var s_p2 = pos - perp * (sleeper_width / 2)
			
			sleeper_points.append(s_p1)
			sleeper_points.append(s_p2)
			
			d += sleeper_spacing

	if sleeper_points.size() > 0:
		var sleepers = RailwaySleepers.new()
		sleepers.sleeper_points = sleeper_points
		sleepers.width = 0.3 * map_scale
		sleepers.z_index = -2
		parent.add_child(sleepers)

func create_platform(points, parent, props):
	if points.size() < 2: return
	
	# Sprawdzamy czy to poligon (obszar) czy linia
	var is_polygon = points[0].distance_to(points[-1]) < 0.1 and points.size() > 2
	
	if is_polygon:
		var poly = Polygon2D.new()
		poly.polygon = points
		poly.texture = sidewalk_tex
		poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		# Skalowanie tekstury, aby nie była rozciągnięta (dostosuj do map_scale)
		poly.texture_scale = Vector2(1.0 / map_scale, 1.0 / map_scale) 
		poly.z_index = -1
		parent.add_child(poly)
	else:
		# Jeśli peron to tylko linia
		var line = Line2D.new()
		line.points = points
		line.width = 3.0 * map_scale
		line.texture = sidewalk_tex
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.z_index = -1
		parent.add_child(line)

class RailwaySleepers extends Node2D:
	var sleeper_points = PackedVector2Array()
	var color = Color(0.35, 0.25, 0.15)
	var width = 6.0
	
	func _draw():
		if sleeper_points.size() >= 2:
			draw_multiline(sleeper_points, color, width)

class OnewayArrows extends Node2D:
	var arrow_points = PackedVector2Array()
	var color = Color(0.613, 0.613, 0.613, 1.0)
	var width = 10.0
	
	func _draw():
		if arrow_points.size() >= 2:
			draw_multiline(arrow_points, color, width)

func is_polygon_convex_custom(points: PackedVector2Array) -> bool:
	var n = points.size()
	if n < 3:
		return false
	var sign_val = 0
	for i in range(n):
		var p1 = points[i]
		var p2 = points[(i + 1) % n]
		var p3 = points[(i + 2) % n]
		var cp = (p2.x - p1.x) * (p3.y - p2.y) - (p2.y - p1.y) * (p3.x - p2.x)
		if cp != 0:
			var current_sign = 1 if cp > 0 else -1
			if sign_val == 0:
				sign_val = current_sign
			elif sign_val != current_sign:
				return false
	return true

func calculate_road_width(props: Dictionary) -> float:
	var highway = props.get("highway", "")
	var is_sidewalk = highway in ["footway", "path", "pedestrian", "cycleway"]
	
	var lane_width_m = 3.2
	var default_lanes = {
		"motorway": 4, "trunk": 3, "primary": 2, "secondary": 2, 
		"tertiary": 2, "residential": 2, "unclassified": 1.4, "service": 1
	}
	
	var lanes = int(props.get("lanes", default_lanes.get(highway, 1)))
	
	if is_sidewalk:
		return 2.0 * map_scale
	else:
		var road_width_m = lanes * lane_width_m
		return clamp(road_width_m * map_scale, 5.0 * map_scale, 15.0 * map_scale)
func is_point_on_road(global_pos: Vector2) -> bool:
	for start_node in road_network:
		for road in road_network[start_node]:
			var points = road["points"]
			var half_width = road["width"] / 2.0
			
			for i in range(points.size() - 1):
				var p1 = points[i]
				var p2 = points[i+1]
				
				var closest_point = Geometry2D.get_closest_point_to_segment(global_pos, p1, p2)
				
				# Dodajemy mały margines błędu (15 pikseli), żeby auto nie "skakało" na krawędziach
				if global_pos.distance_to(closest_point) <= (half_width + 15.0):
					return true 
					
	return false
