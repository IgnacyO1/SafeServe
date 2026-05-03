extends Node2D

# --- KONFIGURACJA ---
var chunk_size_meters = 200.0  # Rozmiar chunka w METRACH (jak w Pythonie)
var map_scale = 10.0           # 1 metr = 10 pikseli (TUTAJ zmieniasz wielkość mapy!)
var load_radius = 2 
var chunk_path = "res://data/map_chunks/"

# To jest faktyczny rozmiar chunka w pikselach Godota
@onready var chunk_size_px = chunk_size_meters * map_scale

var loaded_chunks = {} 

@export var player_path: NodePath
@onready var player = get_node(player_path)

func _process(_delta):
	if player:
		update_chunks()

func update_chunks():
	# Liczymy chunk na podstawie pozycji w pikselach podzielonej przez rozmiar w pikselach
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
	
	for feature in data:
		spawn_feature(feature, chunk_node)

func spawn_feature(feature, parent):
	var points = PackedVector2Array()
	# PRZELICZANIE PUNKTÓW: Metry z JSON * Skala Godota
	for p in feature["geometry"]:
		points.append(Vector2(p[0] * map_scale, p[1] * map_scale))
		
	var type = feature["type"]
	if type == "yes" or type == "building" or feature["props"].has("building"):
		create_building(points, parent)
	else:
		create_road(points, parent)

func create_building(points, parent):
	var body = StaticBody2D.new()
	var visual = Polygon2D.new()
	visual.polygon = points
	visual.color = Color(0.25, 0.25, 0.25)
	
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	
	body.add_child(visual)
	body.add_child(collision)
	parent.add_child(body)

func create_road(points, parent):
	var line = Line2D.new()
	line.points = points
	line.width = 4.0 * map_scale # Szerokość drogi też skalujemy!
	line.default_color = Color(0.15, 0.15, 0.15)
	line.z_index = -1
	parent.add_child(line)
