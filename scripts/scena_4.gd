extends Node2D

@onready var label_czas = $HUD/LabelCzas
@onready var minimapa_bg = Sprite2D.new()
@onready var markers_node = Node2D.new()
@onready var label_skrzynka = $HUD/LabelSkrzynka if has_node("HUD/LabelSkrzynka") else null

var czas = 180.0
var gra_aktywna = true
var faza = "POZARY" # Fazy: POZARY, BABCIA, SKRZYNKA, KONIEC

const OGIEN_SCENA = preload("res://scenes/ogien.tscn")
var WYKRZYKNIK_TEX = preload("res://assets/graphics/scena4_wykrzyknik.png") if ResourceLoader.exists("res://assets/graphics/scena4_wykrzyknik.png") else preload("res://assets/Images/Dot.png")
var MAP_TEX = preload("res://assets/graphics/safeservemap (1).png")

# 10 pozycji ognia rozlozonych po calej mapie (sprawdzone - na bialych korytarzach)
var pozycje_ogni = [
	Vector2(2257, 483),
	Vector2(6149, 505),
	Vector2(3651, 541),
	Vector2(7559, 1054),
	Vector2(4888, 1750),
	Vector2(552, 1876),
	Vector2(6641, 2233),
	Vector2(3390, 2498),
	Vector2(1066, 2790),
	Vector2(6560, 3232),
]
var ognie = []
var gracz


@onready var label_zadanie = Label.new()

func _ready():
	gracz = get_tree().get_nodes_in_group("gracz")[0] if get_tree().get_nodes_in_group("gracz").size() > 0 else null
	
	# Budowa Minimapy i HUD
	var hud = $HUD if has_node("HUD") else CanvasLayer.new()
	if not has_node("HUD"):
		hud.name = "HUD"
		add_child(hud)
		
	# Dodanie wielkiego napisu na środku ekranu
	label_zadanie.text = "ZGAS POZARY! MASZ 3 MINUTY!"
	label_zadanie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_zadanie.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	label_zadanie.position = Vector2(0, 50)
	label_zadanie.set("theme_override_font_sizes/font_size", 40)
	
	# Kolorowanie czasu i zadań z ładnym obramowaniem
	if label_czas:
		label_czas.set("theme_override_colors/font_outline_color", Color.BLACK)
		label_czas.set("theme_override_constants/outline_size", 6)
	if label_skrzynka:
		label_skrzynka.set("theme_override_font_sizes/font_size", 24)
		label_skrzynka.set("theme_override_colors/font_outline_color", Color.BLACK)
		label_skrzynka.set("theme_override_constants/outline_size", 4)
		label_skrzynka.set("theme_override_colors/font_color", Color.RED)
		label_skrzynka.modulate = Color.RED
		label_skrzynka.text = "Zgaś pożary (Podejdź i wciśnij E)"
		label_skrzynka.visible = false
	label_zadanie.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_zadanie.set("theme_override_constants/outline_size", 6)
	label_zadanie.modulate = Color.YELLOW
	hud.add_child(label_zadanie)

	minimapa_bg.texture = MAP_TEX
	minimapa_bg.visible = false
	minimapa_bg.modulate = Color(1, 1, 1, 0.85) # Półprzezroczystość jak w Among Us
	minimapa_bg.position = get_viewport_rect().size / 2.0 
	
	# Obliczanie skali, żeby mapa zmieściła się na ekranie
	var map_size = minimapa_bg.texture.get_size()
	var vp_size = get_viewport_rect().size
	var target_w = vp_size.x * 0.8
	var target_h = vp_size.y * 0.8
	var sc_x = target_w / map_size.x
	var sc_y = target_h / map_size.y
	var sc = min(sc_x, sc_y)
	minimapa_bg.scale = Vector2(sc, sc)

	# Czarny Panel pod mapą z obramowaniem (border)
	var panel = ColorRect.new()
	var border_size = 10
	panel.color = Color(0, 0, 0, 0.7) # Przezroczyste tło
	panel.position = -minimapa_bg.texture.get_size() / 2.0 - Vector2(border_size, border_size)
	panel.size = minimapa_bg.texture.get_size() + Vector2(border_size*2, border_size*2)
	panel.z_index = -1
	minimapa_bg.add_child(panel)
	
	hud.add_child(minimapa_bg)
	minimapa_bg.add_child(markers_node)
	
	# Wczytaj kolizje scian z obrazu (tylko czarne obszary) + granice mapy
	_dodaj_sciany_graniczne()

	
	if gracz:
		# call_deferred aby miec pewnosc ze fizyka jest gotowa zanim przeniesiesz gracza
		gracz.set_deferred("global_position", Vector2(5252, 2687))
		var cam = gracz.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 8192
			cam.limit_bottom = 4096
			cam.zoom = Vector2(1.5, 1.5)
	
	for poz in pozycje_ogni:
		var ogien = OGIEN_SCENA.instantiate()
		ogien.position = poz
		add_child(ogien)
		ognie.append(ogien)

func _process(delta: float) -> void:
	if not gra_aktywna:
		return
		
	# Aktualizacja pozycji gracza na minimapie gdy jest widoczna
	if minimapa_bg.visible:
		_odswiez_minimape()
		# Zamknij mapę gdy gracz się porusza
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_accept"):
			minimapa_bg.visible = false

		
	czas -= delta
	if label_czas:
		label_czas.text = "Czas: " + str(int(czas))
		if czas <= 10:
			label_czas.modulate = Color.RED
		else:
			label_czas.modulate = Color.WHITE
		
	if czas <= 0 and gra_aktywna:
		czas = 0
		przegrana() # Należy przegrać we WSZYSTKICH fazach jeśli czas upłynie
			
	# Chowanie głównego napisu ze środka po pierwszym ruszeniu
	if label_zadanie.visible and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_accept")):
		label_zadanie.visible = false
		if label_skrzynka:
			label_skrzynka.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			# M otwiera/zamyka mapę
			minimapa_bg.visible = !minimapa_bg.visible
			if minimapa_bg.visible:
				_odswiez_minimape()
				if label_zadanie and label_zadanie.visible:
					label_zadanie.visible = false
					if label_skrzynka:
						label_skrzynka.visible = true
		else:
			# Każdy inny klawisz zamyka mapę
			if minimapa_bg.visible:
				minimapa_bg.visible = false
	elif event is InputEventMouseButton and event.pressed:
		# Kliknięcie myszą też zamyka mapę
		if minimapa_bg.visible:
			minimapa_bg.visible = false

func _odswiez_minimape():
	for child in markers_node.get_children():
		child.queue_free()
	
	# Rozmiar swiata gry = rozmiar tekstury mapy
	var map_world_size = Vector2(8192, 4096)
	# Rozmiar tekstury na ekranie po przeskalowaniu
	var tex_size = minimapa_bg.texture.get_size()
	
	# Funkcja przelicza pozycje ze swiata gry na pozycje na minimapie
	# Sprite2D z centered=false ma srodek tekstury jako origin przy dodawaniu dzieci
	# Dzieci sa wzgledem centrum sprite'a
	var get_marker_pos = func(real_pos: Vector2) -> Vector2:
		var pos_norm = real_pos / map_world_size  # 0.0..1.0
		return (pos_norm * tex_size) - (tex_size / 2.0)  # Wzgledem centrum sprite'a
	
	# Zaznacz pożary
	for ogien in ognie:
		if is_instance_valid(ogien):
			var m = Sprite2D.new()
			m.texture = WYKRZYKNIK_TEX
			m.scale = Vector2(2.0, 2.0) # Zwiększony rozmiar płomieni na mapie
			m.z_index = 20 # Zawsze na wierzchu
			m.position = get_marker_pos.call(ogien.position)
			markers_node.add_child(m)
			
	# Zaznacz gracza
	if gracz and is_instance_valid(gracz):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/Images/Dot.png") if ResourceLoader.exists("res://assets/Images/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.8, 0.8)
		m.modulate = Color.GREEN
		m.position = get_marker_pos.call(gracz.global_position)
		m.z_index = 20
		markers_node.add_child(m)
		
	# Zaznacz babcie we wszystkich fazach po pożarach
	if faza == "BABCIA" and is_instance_valid(inst_babcia):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/Images/Dot.png") if ResourceLoader.exists("res://assets/Images/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.DEEP_PINK
		m.position = get_marker_pos.call(inst_babcia.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	# Zaznacz skrzynke
	if faza == "SKRZYNKA" and is_instance_valid(inst_skrzynka):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/Images/Dot.png") if ResourceLoader.exists("res://assets/Images/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.YELLOW
		m.position = get_marker_pos.call(inst_skrzynka.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	# Zaznacz wyjscie (po zebraniu skrzynki)
	if faza == "KONIEC" and is_instance_valid(inst_wyjscie):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/Images/Dot.png") if ResourceLoader.exists("res://assets/Images/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.AQUA
		m.position = get_marker_pos.call(inst_wyjscie.global_position)
		m.z_index = 10
		markers_node.add_child(m)

func zgaszono_ogien(ogien):
	if ognie.has(ogien):
		ognie.erase(ogien)
		print("Pozostalo pożarów: ", ognie.size())
		if ognie.size() <= 0 and faza == "POZARY":
			rozpocznij_faze_babcia()

var inst_babcia = null
var inst_skrzynka = null
var inst_wyjscie = null

func rozpocznij_faze_babcia():
	faza = "BABCIA"
	print("URATUJ BABCIE!")
	if label_czas:
		label_czas.modulate = Color.RED
	label_zadanie.text = "Uratuj Babcię"
	label_zadanie.modulate = Color.RED
	label_zadanie.visible = true # Pokaż napis od nowa gdy zadanie ulega zmianie
	if label_skrzynka:
		label_skrzynka.text = "Znajdź Babcię i kliknij E żeby uratować"
		label_skrzynka.modulate = Color.RED
		label_skrzynka.visible = false # Schowaj dopóki label_zadanie jest widoczne
	# Aktualizujemy mapę, aby kropka babci się pokazała natychmiast jeśli mapa jest otwarta
	if minimapa_bg.visible:
		_odswiez_minimape()
	
	# Spawn Babci - zweryfikowana pozycja daleko od spawna gracza
	var babcia_area = Area2D.new()
	babcia_area.name = "Babcia"
	babcia_area.add_to_group("npc")
	babcia_area.position = Vector2(6963, 614)  # Sprawdzone - jasna podłoga biura

	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	babcia_area.add_child(col)
	
	var spr = Sprite2D.new()
	spr.texture = preload("res://assets/graphics/npc_1_babcia.png") if ResourceLoader.exists("res://assets/graphics/npc_1_babcia.png") else WYKRZYKNIK_TEX
	babcia_area.add_child(spr)
	
	inst_babcia = babcia_area
	add_child(babcia_area)
	
func uratowano_babcie():
	if faza == "BABCIA":
		faza = "SKRZYNKA"
		print("ZNAJDZ CZARNA SKRZYNKE!")
		if label_czas:
			label_czas.modulate = Color.RED
		label_zadanie.text = "Znajdź Czarną Skrzynkę"
		label_zadanie.modulate = Color.RED
		label_zadanie.visible = true
		if label_skrzynka:
			label_skrzynka.text = "Znajdź czarną skrzynkę (żółte światło na mini mapce) i kliknij E"
			label_skrzynka.visible = false
		
		# Spawn Skrzynki
		var skrzynka_area = Area2D.new()
		skrzynka_area.name = "CzarnaSkrzynka"
		skrzynka_area.add_to_group("skrzynka")
		skrzynka_area.position = Vector2(1638, 3072)  # Sprawdzone - lewy dolny obszar biura
		
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(80, 80)
		col.shape = shape
		skrzynka_area.add_child(col)
		
		var spr = Sprite2D.new()
		spr.texture = preload("res://assets/graphics/czarna_skrzynka.png") if ResourceLoader.exists("res://assets/graphics/czarna_skrzynka.png") else WYKRZYKNIK_TEX
		skrzynka_area.add_child(spr)
		
		inst_skrzynka = skrzynka_area
		add_child(skrzynka_area)
		
		if minimapa_bg.visible:
			_odswiez_minimape()

func podniesiono_skrzynke():
	if faza == "SKRZYNKA":
		faza = "KONIEC"
		print("UCIEKAJ DO MAIN MENU!")
		if label_czas:
			label_czas.modulate = Color.RED
		
		# Ustawiamy napis znowu
		label_zadanie.text = "Kieruj się do wyjscia"
		label_zadanie.visible = true
		label_zadanie.modulate = Color.RED
		if label_skrzynka:
			label_skrzynka.text = "Aby opuścić udaj się do wyjścia niebieskiego światło na mapie"
			label_skrzynka.modulate = Color.RED
			label_skrzynka.visible = false
		
		# Spawn Wyjścia
		var wyjscie_area = Area2D.new()
		wyjscie_area.name = "Wyjscie"
		wyjscie_area.add_to_group("wyjscie")
		wyjscie_area.position = Vector2(1638, 614)  # Sprawdzone - lewy gorny obszar biura
		
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(100, 100)
		col.shape = shape
		wyjscie_area.add_child(col)
		
		var spr = Sprite2D.new()
		spr.modulate = Color.AQUA
		spr.texture = WYKRZYKNIK_TEX
		spr.scale = Vector2(3, 3)
		wyjscie_area.add_child(spr)
		
		inst_wyjscie = wyjscie_area
		add_child(wyjscie_area)
		
		if minimapa_bg.visible:
			_odswiez_minimape()
		
func ucieczka_udana():
	if faza == "KONIEC":
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func przegrana():
	gra_aktywna = false
	if label_czas:
		label_czas.text = "PRZEGRANA!"
	print("PRZEGRANA! Czas minął!")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _dodaj_sciany_graniczne():
	# 1. Wczytaj kolizje prawdziwych scian z obrazu (tylko czarne obszary >30px)
	var file = FileAccess.open("res://assets/graphics/scena4_walls.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json_obj = JSON.new()
		var err = json_obj.parse(text)
		if err == OK:
			var data = json_obj.get_data()
			var walls_body = StaticBody2D.new()
			walls_body.name = "ScianyMapy"
			for poly_pts in data:
				var poly = CollisionPolygon2D.new()
				var vec_arr = PackedVector2Array()
				for pt in poly_pts:
					vec_arr.append(Vector2(pt[0], pt[1]))
				poly.polygon = vec_arr
				walls_body.add_child(poly)
			add_child(walls_body)
	
	# 2. Granica zewnetrzna mapy 8192x4096
	var border = StaticBody2D.new()
	border.name = "GranicaMapy"
	var grubosc = 200.0
	var szer = 8192.0
	var wys = 4096.0
	
	var g = CollisionShape2D.new()  # Gorna
	g.shape = RectangleShape2D.new()
	g.shape.size = Vector2(szer + grubosc * 2, grubosc)
	g.position = Vector2(szer / 2, -grubosc / 2)
	border.add_child(g)
	
	var d = CollisionShape2D.new()  # Dolna
	d.shape = RectangleShape2D.new()
	d.shape.size = Vector2(szer + grubosc * 2, grubosc)
	d.position = Vector2(szer / 2, wys + grubosc / 2)
	border.add_child(d)
	
	var l = CollisionShape2D.new()  # Lewa
	l.shape = RectangleShape2D.new()
	l.shape.size = Vector2(grubosc, wys)
	l.position = Vector2(-grubosc / 2, wys / 2)
	border.add_child(l)
	
	var p = CollisionShape2D.new()  # Prawa
	p.shape = RectangleShape2D.new()
	p.shape.size = Vector2(grubosc, wys)
	p.position = Vector2(szer + grubosc / 2, wys / 2)
	border.add_child(p)
	
	add_child(border)
