extends Node2D

@onready var player = $Car

# Cel
var target_pos_px = Vector2(-3136, 3661)

var coords_label: Label
var arrow_sprite: Polygon2D # Zmieniamy na konkretny typ

func _ready():
	# Upewnijmy się, że gracz istnieje
	if not player:
		print("BŁĄD: Nie znaleziono gracza w World!")
	setup_ui()

func setup_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # Upewniamy się, że UI jest na samym wierzchu
	add_child(canvas)
	
	coords_label = Label.new()
	coords_label.position = Vector2(20, 20)
	coords_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(coords_label)
	
	# Kontener jako Marker2D lepiej znosi rotację w 2D niż Control
	var arrow_container = Marker2D.new()
	arrow_container.position = Vector2(get_viewport_rect().size.x - 100, 100)
	canvas.add_child(arrow_container)
	
	arrow_sprite = Polygon2D.new()
	# Rysujemy strzałkę tak, aby (0,0) było w jej środku/podstawie
	arrow_sprite.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(15, 15), Vector2(0, 5), Vector2(-15, 15)
	])
	arrow_sprite.color = Color.RED
	arrow_container.add_child(arrow_sprite)

func _process(delta):
	if is_instance_valid(player) and arrow_sprite:
		var player_pos = player.global_position
		var dist_vec = target_pos_px - player_pos
		
		# Debugowanie w konsoli (jeśli to widzisz, to znaczy że skrypt działa)
		# print("Kąt do celu: ", dist_vec.angle()) 

		# AKTUALIZACJA TEKSTU
		var dist_m = dist_vec.length() / 20.0
		coords_label.text = "GPS: %d, %d\nDO CELU: %d m" % [player_pos.x, player_pos.y, int(dist_m)]
		
		# OBLICZANIE ROTACJI
		# 1. Kąt wektora do celu
		var final_angle = dist_vec.angle() + PI/2
		
		# 2. JEŚLI KAMERA SIĘ OBRACA: 
		# Musimy odjąć rotację gracza, żeby strzałka "na ekranie" 
		# wskazywała realny kierunek świata.
		final_angle -= player.rotation 
		
		arrow_sprite.rotation = final_angle

		# TEST WIROWANIA (Odkomentuj TYLKO linię poniżej, a zakomentuj arrow_sprite.rotation powyżej)
		# arrow_sprite.rotation += delta * 10
