extends Node2D

# --- UNIKALNE USTAWIENIA TEJ TRASY ---
var start_pos_px = Vector2(-2356, 44164)
var target_pos_px = Vector2(-62668, 73086)

@onready var player = $Car
@onready var map_manager = $MapManager

var coords_label: Label
var arrow_sprite: Polygon2D

func _ready():
	if not player:
		print("BŁĄD: Brak gracza!")
		return
		
	# 1. Konfigurujemy mapę pod tę konkretną trasę
	setup_level()
	# 2. Tworzymy UI
	setup_ui()

func setup_level():
	# Mówimy managerowi, gdzie ma zacząć generować świat
	if map_manager:
		map_manager.initialize_map(start_pos_px)

func setup_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	coords_label = Label.new()
	coords_label.position = Vector2(20, 20)
	coords_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(coords_label)
	
	var arrow_container = Marker2D.new()
	arrow_container.position = Vector2(get_viewport_rect().size.x - 100, 100)
	canvas.add_child(arrow_container)
	
	arrow_sprite = Polygon2D.new()
	arrow_sprite.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(15, 15), Vector2(0, 5), Vector2(-15, 15)
	])
	arrow_sprite.color = Color.RED
	arrow_container.add_child(arrow_sprite)

func _process(_delta):
	if is_instance_valid(player) and arrow_sprite:
		var player_pos = player.global_position
		var dist_vec = target_pos_px - player_pos
		var dist_m = dist_vec.length() / 20.0
		
		coords_label.text = "GPS: %d, %d\nDO CELU: %d m" % [player_pos.x, player_pos.y, int(dist_m)]
		
		# TWOJA POPRAWIONA ROTACJA
		var angle_to_target = dist_vec.angle()
		var final_angle = angle_to_target - player.rotation
		# final_angle -= PI/2 # Odkomentuj jeśli znów ucieknie o 90 stopni
		
		arrow_sprite.rotation = final_angle
