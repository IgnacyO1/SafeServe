extends Node2D

@onready var label_czas = $HUD/LabelCzas
@onready var minimapa_bg = Sprite2D.new()
@onready var markers_node = Node2D.new()

var czas = 180.0
var gra_aktywna = true
var faza = "POZARY" # Fazy: POZARY, BABCIA, SKRZYNKA, KONIEC

const OGIEN_SCENA = preload("res://scenes/ogien.tscn")
var WYKRZYKNIK_TEX = preload("res://assets/graphics/scena4_wykrzyknik.png") if ResourceLoader.exists("res://assets/graphics/scena4_wykrzyknik.png") else preload("res://assets/images/Dot.png")
var MAP_TEX = preload("res://assets/graphics/scena4_map.png") if ResourceLoader.exists("res://assets/graphics/scena4_map.png") else preload("res://assets/graphics/scena4_nowe_tło.png")

var pozycje_ogni = [
	Vector2(550, 480), # Poprawione bardziej na srodek bieli
	Vector2(850, 520),
	Vector2(1480, 520)
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
	label_zadanie.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_zadanie.set("theme_override_constants/outline_size", 6)
	label_zadanie.modulate = Color.YELLOW
	hud.add_child(label_zadanie)

	minimapa_bg.texture = MAP_TEX
	minimapa_bg.visible = false
	minimapa_bg.modulate = Color(1, 1, 1, 0.85) # Półprzezroczystość jak w Among Us
	# Środek ekranu pobrany bezpośrednio z ustawień okna gry, uodporniony na rozdzielczości
	minimapa_bg.position = get_viewport_rect().size / 2.0 
	minimapa_bg.scale = Vector2(0.8, 0.8) # Powiększono mapę

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
	
	# Automatyczne ściany (border) blokujące wyjście poza mapę 1920x1080
	var map_bounds = StaticBody2D.new()
	var sz_x = 1920
	var sz_y = 1080
	var grubosc = 100
	
	# Górna ściana
	var top = CollisionShape2D.new()
	top.shape = RectangleShape2D.new()
	top.shape.size = Vector2(sz_x + grubosc*2, grubosc)
	top.position = Vector2(sz_x/2, -grubosc/2)
	map_bounds.add_child(top)
	
	# Dolna ściana
	var bot = CollisionShape2D.new()
	bot.shape = RectangleShape2D.new()
	bot.shape.size = Vector2(sz_x + grubosc*2, grubosc)
	bot.position = Vector2(sz_x/2, sz_y + grubosc/2)
	map_bounds.add_child(bot)
	
	# Lewa ściana
	var left = CollisionShape2D.new()
	left.shape = RectangleShape2D.new()
	left.shape.size = Vector2(grubosc, sz_y)
	left.position = Vector2(-grubosc/2, sz_y/2)
	map_bounds.add_child(left)
	
	# Prawa ściana
	var right = CollisionShape2D.new()
	right.shape = RectangleShape2D.new()
	right.shape.size = Vector2(grubosc, sz_y)
	right.position = Vector2(sz_x + grubosc/2, sz_y/2)
	map_bounds.add_child(right)
	
	add_child(map_bounds)
	
	for poz in pozycje_ogni:
		var ogien = OGIEN_SCENA.instantiate()
		ogien.position = poz
		add_child(ogien)
		ognie.append(ogien)

func _process(delta: float) -> void:
	if not gra_aktywna:
		return
		
	# Chowanie mapy przy ruchu
	if minimapa_bg.visible and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_M and event.pressed and not event.echo:
		minimapa_bg.visible = !minimapa_bg.visible
		if minimapa_bg.visible:
			_odswiez_minimape()
			if label_zadanie:
				label_zadanie.visible = false # Chowa napis przy otwarciu mapy

func _odswiez_minimape():
	for child in markers_node.get_children():
		child.queue_free()
		
	var tex_size = minimapa_bg.texture.get_size()
	var skala_mapy = tex_size # Traktujemy wielkość obrazka = wielkość Godota
	
	# Funkcja pomocnicza do przeliczeń (środek tekstury to 0,0 w Sprite2D pozycjonowaniu dzieci)
	var get_marker_pos = func(real_pos: Vector2) -> Vector2:
		var pos_norm = real_pos / skala_mapy
		return (pos_norm * tex_size) - (tex_size / 2.0)
	
	# Zaznacz pożary
	for ogien in ognie:
		if is_instance_valid(ogien):
			var m = Sprite2D.new()
			m.texture = WYKRZYKNIK_TEX
			m.position = get_marker_pos.call(ogien.position)
			markers_node.add_child(m)
			
	# Zaznacz gracza
	if gracz and is_instance_valid(gracz):
		var m = Sprite2D.new()
		m.texture = WYKRZYKNIK_TEX
		m.modulate = Color.GREEN
		m.position = get_marker_pos.call(gracz.global_position)
		markers_node.add_child(m)
		
	# Zaznacz babcie we wszystkich fazach po pożarach
	if faza == "BABCIA" and is_instance_valid(inst_babcia):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/images/Dot.png") if ResourceLoader.exists("res://assets/images/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.DEEP_PINK
		m.position = get_marker_pos.call(inst_babcia.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	# Zaznacz skrzynke
	if faza == "SKRZYNKA" and is_instance_valid(inst_skrzynka):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/images/Dot.png") if ResourceLoader.exists("res://assets/images/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.YELLOW
		m.position = get_marker_pos.call(inst_skrzynka.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	# Zaznacz wyjscie (po zebraniu skrzynki)
	if faza == "KONIEC" and is_instance_valid(inst_wyjscie):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/images/Dot.png") if ResourceLoader.exists("res://assets/images/Dot.png") else WYKRZYKNIK_TEX
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
		label_czas.text = "Uratuj babcie (fioletowe światło)"
		label_czas.modulate = Color.RED
	label_zadanie.text = "URATUJ BABCIE! DAJ JEJ MASKE (E)"
	label_zadanie.modulate = Color.RED
	label_zadanie.visible = true # Pokaż napis od nowa gdy zadanie ulega zmianie
	# Aktualizujemy mapę, aby kropka babci się pokazała natychmiast jeśli mapa jest otwarta
	if minimapa_bg.visible:
		_odswiez_minimape()
	
	# Spawn Babci z kodu
	var babcia_area = Area2D.new()
	babcia_area.name = "Babcia"
	babcia_area.add_to_group("npc")
	babcia_area.position = Vector2(210, 100) # Pozycja Babci w pokoju
	
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
			label_czas.text = "Znajdź czarna skrzynkę (żółte światło)"
			label_czas.modulate = Color.ORANGE
		label_zadanie.text = "SZYBKO ZNAJDZ CZARNA SKRZYNKE (E)"
		label_zadanie.modulate = Color.ORANGE
		label_zadanie.visible = true
		
		# Spawn Skrzynki
		var skrzynka_area = Area2D.new()
		skrzynka_area.name = "CzarnaSkrzynka"
		skrzynka_area.add_to_group("skrzynka")
		skrzynka_area.position = Vector2(1880, 500) # Pozycja skrzynki
		
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
			label_czas.text = "Uciekaj do Drzwi (niebieskie światło)"
			label_czas.modulate = Color.RED
		
		# Ustawiamy napis znowu
		label_zadanie.text = "Uciekaj ze skrzynką do Drzwi (Niebieskie Światło)"
		label_zadanie.visible = true
		label_zadanie.modulate = Color.RED
		
		# Spawn Wyjścia
		var wyjscie_area = Area2D.new()
		wyjscie_area.name = "Wyjscie"
		wyjscie_area.add_to_group("wyjscie")
		wyjscie_area.position = Vector2(200, 500) # Startowa okolica na przyklad
		
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
