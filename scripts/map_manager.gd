extends Node2D

# --- KONFIGURACJA ---
var chunk_size_meters = 200.0
var map_scale = 20.0
var load_radius = 1
var chunk_path = "res://data/map_chunks/"

@onready var chunk_size_px = chunk_size_meters * map_scale

# --- ZASOBY ---
@onready var grass_tex = preload("res://assets/graphics/tileable_grass_00.png")
@onready var asphalt_tex = preload("res://assets/graphics/01tizeta_asphalts.png")
@onready var tree_tex = preload("res://assets/graphics/tree_top.png")
@onready var sidewalk_tex = preload("res://assets/graphics/pavement_2.png")
@onready var water_tex = preload("res://assets/graphics/water.tres") # To jest Twój AnimatedTexture
var loaded_chunks = {} 


#NPC POJAZDY
@export var traffic_density = 1 # Szansa (0-1), że na danej drodze pojawi się auto
@onready var npc_car_scene = preload("res://scenes/NPCCar.tscn") # Ścieżka do Twojej sceny NPC

@export var player_path: NodePath
@onready var player = get_node(player_path)

func _process(_delta):
	if player:
		update_chunks()

func update_chunks():
	var p_x = int(floor(player.global_position.x / chunk_size_px))
	var p_y = int(floor(player.global_position.y / chunk_size_px))
	
	var needed_ids = []
	for x in range(p_x - load_radius, p_x + load_radius + 1):
		for y in range(p_y - load_radius, p_y + load_radius + 1):
			needed_ids.append(str(x) + "_" + str(y))
	
	for c_id in loaded_chunks.keys():
		if not c_id in needed_ids:
			loaded_chunks[c_id].queue_free()
			loaded_chunks.erase(c_id)
			
	for c_id in needed_ids:
		if not loaded_chunks.has(c_id):
			load_chunk_from_json(c_id)

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
	
	# 1. TŁO CHUNKA (Trawa)
	var coords = c_id.split("_")
	var cx = int(coords[0])
	var cy = int(coords[1])
	
	# --- Zmień te linie w sekcji TŁO CHUNKA ---
	var bg = Sprite2D.new()
	bg.texture = grass_tex
	bg.centered = false
	bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED # To włącza kafelkowanie
	bg.region_enabled = true
	# Region musi być w pikselach (rozmiar chunka), wtedy tekstura wypełni go kafelkami
	bg.region_rect = Rect2(0, 0, chunk_size_px, chunk_size_px) 
	bg.position = Vector2(cx * chunk_size_px, cy * chunk_size_px)
	bg.z_index = -10
	chunk_node.add_child(bg)
	
	for feature in data:
		spawn_feature(feature, chunk_node)

func spawn_feature(feature, parent):
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

	# --- NOWOŚĆ: Przystanki i Perony ---
	if props.get("railway") == "platform" or props.has("public_transport") or props.get("highway") == "platform":
		create_platform(points, parent, props)
		return

	# Woda
	if props.has("water") or props.has("waterway") or props.get("natural") == "water":
		create_water(points, parent, props)
		return

	# Tory (zostawiamy tylko prawdziwe tory)
	if props.has("railway") and props.get("railway") in ["tram", "rail", "subway"]:
		create_railway(points, parent, props)
		return

	# Budynki i Drogi
	if type == "building" or props.has("building"):
		create_building(points, parent)
	else:
		create_road(points, parent, props)

func create_building(points, parent):
	# 1. Podstawowa walidacja danych z OSM
	if points.size() < 3:
		return
	
	# 2. Czyszczenie geometrii
	# OSM czasem duplikuje punkty lub ma "brudne" dane. 
	# offset_polygon(points, 0) to szybki sposób na naprawienie struktury poligonu.
	var cleaned_polygons = Geometry2D.offset_polygon(points, 0.0)
	if cleaned_polygons.size() == 0:
		return
	var clean_points = cleaned_polygons[0]

	# 3. Rozwiązanie problemu "duchów" - Dekompozycja
	# Dzielimy budynek (który może być wklęsły, np. w kształcie L) 
	# na kilka mniejszych poligonów wypukłych (convex), które silnik fizyki rozumie idealnie.
	var convex_polygons = Geometry2D.decompose_polygon_in_convex(clean_points)
	
	var body = StaticBody2D.new()
	body.collision_layer = 1 # Warstwa ŚWIAT
	body.collision_mask = 0  # Budynek sam nie musi nic wykrywać
	
	# --- WIZUALIZACJA (Dach) ---
	var visual = Polygon2D.new()
	visual.polygon = clean_points
	visual.color = Color(0.3, 0.3, 0.35)
	visual.z_index = 2
	body.add_child(visual)

	# --- WIZUALIZACJA (Cień) ---
	var shadow = Polygon2D.new()
	shadow.polygon = clean_points
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(5, 5) # Lekkie przesunięcie dla efektu 3D
	shadow.z_index = 1
	body.add_child(shadow)

	# --- WIZUALIZACJA (Obrys) ---
	var outline = Line2D.new()
	var opoints = clean_points
	opoints.append(clean_points[0]) # Zamknięcie pętli obrysu
	outline.points = opoints
	outline.width = 2.0
	outline.default_color = Color(0.1, 0.1, 0.1)
	outline.z_index = 3
	body.add_child(outline)

	# --- KOLIZJA (Fizyka) ---
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
	
	var is_drivable = highway in ["primary", "secondary", "tertiary", "residential", "service"]
	
	if is_drivable and points.size() >= 2:
		spawn_traffic_on_path(points, parent, props)
	
	var lane_width_m = 3.2
	var default_lanes = {
		"motorway": 4, "trunk": 3, "primary": 2, "secondary": 2, 
		"tertiary": 2, "residential": 2, "unclassified": 1.4, "service": 1
	}
	
	var lanes = int(props.get("lanes", default_lanes.get(highway, 1)))
	
	if is_sidewalk:
		road.width = 2.0 * map_scale
		road.texture = sidewalk_tex
		road.z_index = -3
		road.default_color = Color(0.8, 0.8, 0.8)
	else:
		var road_width_m = lanes * lane_width_m
		road.width = clamp(road_width_m * map_scale, 5.0 * map_scale, 15.0 * map_scale)
		road.texture = asphalt_tex
		road.z_index = -2
		road.default_color = Color.WHITE
	
	road.texture_mode = Line2D.LINE_TEXTURE_TILE
	road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	road.begin_cap_mode = Line2D.LINE_CAP_ROUND
	road.end_cap_mode = Line2D.LINE_CAP_ROUND
	road.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(road)
	
	# RYSUJ STRZAŁKI DLA JEDNOKIERUNKOWYCH
	if is_oneway and points.size() >= 2:
		render_oneway_arrows(points, parent)

func render_oneway_arrows(points, parent):
	var arrow_spacing = 40.0 * map_scale # Strzałka co 40 metrów
	var arrow_size = 2.0 * map_scale     # Rozmiar ramion strzałki
	
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i+1]
		var dir = (p2 - p1).normalized()
		var segment_len = p1.distance_to(p2)
		
		var d = arrow_spacing / 2.0 # Zacznij kawałek od początku segmentu
		while d < segment_len:
			var pos = p1 + dir * d
			
			# Rysujemy prostą strzałkę "V" wskazującą kierunek
			var arrow = Line2D.new()
			
			# Obliczamy ramiona strzałki
			var left_arm = pos - dir * arrow_size + dir.rotated(PI/2) * (arrow_size * 0.5)
			var right_arm = pos - dir * arrow_size + dir.rotated(-PI/2) * (arrow_size * 0.5)
			
			arrow.points = PackedVector2Array([left_arm, pos, right_arm])
			arrow.width = 0.5 * map_scale
			arrow.default_color = Color(0.613, 0.613, 0.613, 1.0) # Półprzezroczysty biały
			arrow.z_index = -1 # Nad asfaltem
			
			parent.add_child(arrow)
			d += arrow_spacing
func create_tree(pos, parent):
	var tree_node = StaticBody2D.new()
	tree_node.collision_layer = 1
	tree_node.collision_mask = 0
	tree_node.position = pos
	
	# 1. Cień drzewa (lekko przesunięte czarne kółko lub kopia sprita)
	var shadow = Sprite2D.new()
	shadow.texture = tree_tex
	shadow.modulate = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(3, 3)
	shadow.scale = Vector2(0.1, 0.1) * map_scale # Dopasuj skalę do mapy
	shadow.z_index = 1
	
	# 2. Korona drzewa
	var visual = Sprite2D.new()
	visual.texture = tree_tex
	visual.scale = Vector2(0.1, 0.1) * map_scale
	visual.z_index = 4 # Wyżej niż dachy budynków (opcjonalnie)
	
	# 3. Kolizja (okrągła, żeby auto mogło się obetrzeć o drzewo)
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 0.4 * map_scale # Promień pnia/kolizji
	col.shape = circle
	
	tree_node.add_child(shadow)
	tree_node.add_child(visual)
	tree_node.add_child(col)
	parent.add_child(tree_node)

func create_water(points, parent, props):
	# 1. Podstawowa walidacja
	if points.size() < 3: 
		return
	
	# 2. Sprawdzamy, czy to jest zamknięty obszar (Poligon)
	# Sprawdzamy czy pierwszy i ostatni punkt są blisko siebie
	var is_polygon = points[0].distance_to(points[-1]) < 0.1
	
	if not is_polygon:
		# Jeśli to linia (rzeczka/kanał), a nie chcemy jej rysować - kończymy funkcję tutaj
		return

	# 3. Jeśli doszliśmy tutaj, znaczy że mamy obszar (np. Wisłę)
	var water_node = Polygon2D.new()
	water_node.polygon = points
	
	# Ustawienia tekstury (AnimatedTexture)
	water_node.texture = water_tex
	water_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	water_node.texture_scale = Vector2(2.0, 2.0) 
	
	# Ustawienia warstw
	water_node.z_index = -5
	
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
	
	var total_dist = 0.0
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
			
			var sleeper = Line2D.new()
			sleeper.points = PackedVector2Array([s_p1, s_p2])
			sleeper.width = 0.3 * map_scale
			sleeper.default_color = Color(0.35, 0.25, 0.15) # Brązowy drewniany
			sleeper.z_index = -2 # Pod szynami
			parent.add_child(sleeper)
			
			d += sleeper_spacing

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
		
func spawn_traffic_on_path(points, parent, props):
	# 1. Tworzymy ścieżkę dla NPC
	var path = Path2D.new()
	var curve = Curve2D.new()
	
	for p in points:
		curve.add_point(p)
	path.curve = curve
	parent.add_child(path)
	
	# 2. Decydujemy czy i ile aut postawić na tej drodze
	# Krótkie drogi mają mniejszą szansę na auto
	var road_length = curve.get_baked_length()
	var num_cars = int(road_length / (100.0 * map_scale) * traffic_density)
	
	for i in range(num_cars):
		if randf() > 0.5: # Nie każda droga musi być pełna
			create_npc_on_path(path, road_length)

func create_npc_on_path(path, road_length):
	# PathFollow2D to węzeł, który "jeździ" po Path2D
	var follow = PathFollow2D.new()
	path.add_child(follow)
	
	# Wyłączamy rotację, jeśli chcemy ją kontrolować sami, 
	# ale domyślnie "rotates = true" sprawi, że auto samo skręca!
	follow.rotates = true 
	follow.loop = true # Auto po dojechaniu do końca wraca na początek (lub znika)
	
	var npc = npc_car_scene.instantiate()
	follow.add_child(npc)
	
	# Losujemy parametry
	var random_speed = randf_range(200.0, 400.0) * map_scale / 20.0
	var start_pos = randf_range(0, road_length)
	
	# Dodajemy skrypt sterujący ruchem follow (można to zrobić w NPCCar lub tu)
	var mover = Node.new() 
	mover.set_script(load("res://scripts/path_mover.gd"))
	mover.speed = random_speed
	follow.add_child(mover)
	
	follow.progress = start_pos
