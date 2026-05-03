extends Node2D

# --- KONFIGURACJA (musi być taka sama jak w Pythonie) --- res://data/map_preprocessing.py
var chunk_size = 200.0 
var load_radius = 2 # ile chunków w każdą stronę wczytać
var chunk_path = "res://data/map_chunks/"

var loaded_chunks = {} # Słownik: { "x_y": Node2D }

@export var player_path: NodePath
@onready var player = get_node(player_path)

func _process(_delta):
	if player:
		update_chunks()

func update_chunks():
	# 1. Oblicz aktualny chunk gracza
	var p_x = int(floor(player.global_position.x / chunk_size))
	var p_y = int(floor(player.global_position.y / chunk_size))
	
	var needed_ids = []
	
	# 2. Wyznacz listę chunków potrzebnych wokół gracza
	for x in range(p_x - load_radius, p_x + load_radius + 1):
		for y in range(p_y - load_radius, p_y + load_radius + 1):
			needed_ids.append(str(x) + "_" + str(y))
	
	# 3. Usuń te, których już nie potrzebujemy
	for c_id in loaded_chunks.keys():
		if not c_id in needed_ids:
			loaded_chunks[c_id].queue_free()
			loaded_chunks.erase(c_id)
			
	# 4. Wczytaj nowe
	for c_id in needed_ids:
		if not loaded_chunks.has(c_id):
			load_chunk_from_json(c_id)

func load_chunk_from_json(c_id):
	var file_name = chunk_path + "chunk_" + c_id + ".json"
	
	if not FileAccess.file_exists(file_name):
		return # Brak danych dla tego obszaru (np. koniec mapy)
		
	var file = FileAccess.open(file_name, FileAccess.READ)
	var json_string = file.get_as_text()
	var data = JSON.parse_string(json_string)
	
	if data == null: return

	# Stwórz kontener na chunk
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_" + c_id
	add_child(chunk_node)
	loaded_chunks[c_id] = chunk_node
	
	# Generuj obiekty
	for feature in data:
		spawn_feature(feature, chunk_node)

func spawn_feature(feature, parent):
	var points = PackedVector2Array()
	for p in feature["geometry"]:
		points.append(Vector2(p[0], p[1]))
		
	var type = feature["type"]
	
	if type == "yes" or type == "building": # Budynki
		create_building(points, parent)
	else: # Reszta to prawdopodobnie drogi (highway)
		create_road(points, parent)

func create_building(points, parent):
	var body = StaticBody2D.new()
	
	# Grafika (szary kształt)
	var visual = Polygon2D.new()
	visual.polygon = points
	visual.color = Color(0.25, 0.25, 0.25) # Ciemno-szary
	
	# Kolizja (fizyka)
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	
	body.add_child(visual)
	body.add_child(collision)
	parent.add_child(body)

func create_road(points, parent):
	var line = Line2D.new()
	line.points = points
	line.width = 10.0 # Możesz dostosować szerokość drogi
	line.default_color = Color(0.15, 0.15, 0.15) # Asfalt
	line.z_index = -1 # Drogi pod budynkami
	parent.add_child(line)
