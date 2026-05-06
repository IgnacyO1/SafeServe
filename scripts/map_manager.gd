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

var loaded_chunks = {} 

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
	# Sprawdzamy czy to punkt (drzewo)
	if feature["props"].get("natural") == "tree" or feature["type"] == "tree":
		var pos = Vector2(feature["geometry"][0][0] * map_scale, feature["geometry"][0][1] * map_scale)
		create_tree(pos, parent)
		return # Kończymy, żeby nie próbowało rysować linii/poligonów
	
	var points = PackedVector2Array()
	for p in feature["geometry"]:
		points.append(Vector2(p[0] * map_scale, p[1] * map_scale))
		
	var type = feature["type"]
	var props = feature["props"]
	var highway_type = props.get("highway", "")

	# Definiujemy co jest chodnikiem
	var is_sidewalk = highway_type in ["footway", "path", "pedestrian", "cycleway", "steps"]

	if type == "yes" or type == "building" or props.has("building"):
		create_building(points, parent)
	elif is_sidewalk:
		create_road(points, parent, true) # Dodajemy parametr is_sidewalk = true
	else:
		create_road(points, parent, false) # is_sidewalk = false

func create_building(points, parent):
	var body = StaticBody2D.new()
	
	# Cień budynku (przesunięty czarny poligon)
	var shadow = Polygon2D.new()
	shadow.polygon = points
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(5, 5)
	shadow.z_index = 1
	
	# Dach budynku
	var visual = Polygon2D.new()
	visual.polygon = points
	visual.color = Color(0.3, 0.3, 0.35) # Lekki błękit/szary
	visual.z_index = 2
	
	# Obrys dachu
	var outline = Line2D.new()
	var opoints = points
	opoints.append(points[0]) # domknięcie
	outline.points = opoints
	outline.width = 2.0
	outline.default_color = Color(0.1, 0.1, 0.1)
	outline.z_index = 3
	
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	
	body.add_child(shadow)
	body.add_child(visual)
	body.add_child(outline)
	body.add_child(collision)
	parent.add_child(body)

func create_road(points, parent, is_sidewalk: bool):
	var road = Line2D.new()
	road.points = points
	
	if is_sidewalk:
		road.width = 2.0 * map_scale # Chodnik jest znacznie węższy
		road.texture = sidewalk_tex
		road.z_index = -3 # Chodniki pod jezdniami (opcjonalnie)
		road.default_color = Color(0.8, 0.8, 0.8) # Jaśniejszy kolor dla tekstury
	else:
		road.width = 5.0 * map_scale # Normalna szerokość jezdni
		road.texture = asphalt_tex
		road.z_index = -2
		road.default_color = Color.WHITE

	road.texture_mode = Line2D.LINE_TEXTURE_TILE
	road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# Zaokrąglone końce dróg, żeby lepiej się łączyły
	road.begin_cap_mode = Line2D.LINE_CAP_ROUND
	road.end_cap_mode = Line2D.LINE_CAP_ROUND
	road.joint_mode = Line2D.LINE_JOINT_ROUND
	
	parent.add_child(road)
	
	# Rysuj pasy tylko na jezdniach (nie na chodnikach)
	if not is_sidewalk:
		var stripes = Line2D.new()
		stripes.points = points
		stripes.width = 0.1 * map_scale
		stripes.default_color = Color(1, 1, 1, 0.4)
		stripes.z_index = -1
		parent.add_child(stripes)

func create_tree(pos, parent):
	var tree_node = StaticBody2D.new()
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
