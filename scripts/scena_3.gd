extends Node2D

@onready var label_czas = $HUD/LabelCzas
@onready var minimapa_bg = Sprite2D.new()
@onready var markers_node = Node2D.new()
@onready var label_skrzynka = $HUD/LabelSkrzynka if has_node("HUD/LabelSkrzynka") else null

var czas = 240.0
var gra_aktywna = true
var faza = "DRZWI"  # DRZWI -> POZARY_I_SPRZATACZ -> SKRZYNKA -> KONIEC

const OGIEN_SCENA = preload("res://scenes/ogien.tscn")
var WYKRZYKNIK_TEX = preload("res://assets/graphics/scena4_wykrzyknik.png") if ResourceLoader.exists("res://assets/graphics/scena4_wykrzyknik.png") else preload("res://assets/graphics/Dot.png")
var MAP_TEX_ZAMKNIETE = preload("res://assets/graphics/mapasafeserve.png")
var MAP_TEX_OTWARTE = preload("res://assets/graphics/mapasafeserve.png")
var SIEKIRA_TEX = preload("res://assets/graphics/siekira_scena4.png")

var VIDEO_PATH = "res://assets/Videos/cutscean2.ogv" 
var AUDIO_PATH = "res://assets/Sounds/znalazłem_czaną_skrzynkę.mp3" 

var video_player: VideoStreamPlayer = null
var audio_player: AudioStreamPlayer = null 

var pozycje_ogni = [
	Vector2(2257, 483), Vector2(3651, 541),
	Vector2(7000, 2000), Vector2(4888, 1750), Vector2(552, 1876),
	Vector2(6641, 2233), Vector2(3390, 2498), Vector2(1066, 2790),
	Vector2(6560, 3232),
	Vector2(1500, 1200), Vector2(2800, 1500), Vector2(3500, 1200),
	Vector2(4200, 800), Vector2(1800, 2200), Vector2(2500, 2800), Vector2(5200, 2500), Vector2(5800, 1000),
	Vector2(3000, 800), Vector2(1200, 1500)
]
var ognie = []
var gracz
var czas_do_rozrostu = 5.0

# DRZWI (rąbanie)
var drzwi_hp = 30.0
var drzwi_max_hp = 30.0
var siekira_pivot: Node2D = null
var siekira_sprite: Sprite2D = null
var drzwi_pasek: ColorRect = null
var drzwi_pasek_bg: ColorRect = null
var drzwi_label: Label = null
var jest_rabanie = false
var rabanie_kat = 0.0
var rabanie_cooldown = 0.0

# Fade
var fade_rect: ColorRect = null

# Obiekty faz
@onready var sprzatacz_npc = $Sprzątacz if has_node("Sprzątacz") else null
var inst_skrzynka = null
var inst_wyjscie = null
var sprzatacz_uratowany = false

@onready var label_zadanie = Label.new()

func _ready():
	GameConfig.save_level("res://scenes/scena_3.tscn")
	gracz = get_tree().get_nodes_in_group("gracz")[0] if get_tree().get_nodes_in_group("gracz").size() > 0 else null
	
	# Ukryj sprzątacza na samym początku przed otwarciem drzwi
	if sprzatacz_npc:
		sprzatacz_npc.visible = false
	
	var hud = $HUD if has_node("HUD") else CanvasLayer.new()
	if not has_node("HUD"):
		hud.name = "HUD"
		add_child(hud)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 100
	hud.add_child(fade_rect)
	_fade_in(1.5)
	
	label_zadanie.text = "ROZWAL DRZWI SIEKIERĄ!\nWciskaj E przy drzwiach!"
	label_zadanie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_zadanie.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	label_zadanie.position = Vector2(0, 50)
	label_zadanie.set("theme_override_font_sizes/font_size", 40)
	label_zadanie.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_zadanie.set("theme_override_constants/outline_size", 6)
	label_zadanie.modulate = Color.ORANGE
	hud.add_child(label_zadanie)

	if label_czas:
		label_czas.set("theme_override_colors/font_outline_color", Color.BLACK)
		label_czas.set("theme_override_constants/outline_size", 6)
		label_czas.visible = false 
	if label_skrzynka:
		label_skrzynka.set("theme_override_font_sizes/font_size", 24)
		label_skrzynka.set("theme_override_colors/font_outline_color", Color.BLACK)
		label_skrzynka.set("theme_override_constants/outline_size", 4)
		label_skrzynka.set("theme_override_colors/font_color", Color.RED)
		label_skrzynka.modulate = Color.ORANGE
		label_skrzynka.text = "Podejdź do drzwi i wciskaj E!"
		label_skrzynka.visible = true

	minimapa_bg.texture = MAP_TEX_ZAMKNIETE
	minimapa_bg.visible = false
	minimapa_bg.modulate = Color(1, 1, 1, 0.85)
	minimapa_bg.position = get_viewport_rect().size / 2.0
	var map_size = minimapa_bg.texture.get_size()
	var vp_size = get_viewport_rect().size
	var sc = min(vp_size.x * 0.8 / map_size.x, vp_size.y * 0.8 / map_size.y)
	minimapa_bg.scale = Vector2(sc, sc)
	var panel = ColorRect.new()
	panel.color = Color(0, 0, 0, 0.7)
	panel.position = -minimapa_bg.texture.get_size() / 2.0 - Vector2(10, 10)
	panel.size = minimapa_bg.texture.get_size() + Vector2(20, 20)
	panel.z_index = -1
	minimapa_bg.add_child(panel)
	hud.add_child(minimapa_bg)
	minimapa_bg.add_child(markers_node)

	_dodaj_sciany_graniczne()

	if gracz:
		gracz.set_deferred("global_position", local_to_world(Vector2(7500, 1600)))
		var cam = gracz.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 8192
			cam.limit_bottom = 4096
			cam.zoom = Vector2(1.3, 1.3)

	_stworz_siekire()
	_stworz_pasek_drzwi(hud)

func _stworz_siekire():
	if not gracz: return
	siekira_pivot = Node2D.new()
	siekira_pivot.z_index = 15
	gracz.add_child(siekira_pivot)
	siekira_sprite = Sprite2D.new()
	siekira_sprite.texture = SIEKIRA_TEX
	siekira_sprite.scale = Vector2(0.3, 0.3)
	siekira_sprite.offset = Vector2(-SIEKIRA_TEX.get_size().x * 0.35, -SIEKIRA_TEX.get_size().y * 0.35)
	siekira_sprite.position = Vector2.ZERO
	siekira_sprite.visible = true
	siekira_pivot.add_child(siekira_sprite)

func _stworz_pasek_drzwi(hud):
	drzwi_pasek_bg = ColorRect.new()
	drzwi_pasek_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	drzwi_pasek_bg.position = Vector2(760, 900)
	drzwi_pasek_bg.size = Vector2(400, 30)
	hud.add_child(drzwi_pasek_bg)
	
	drzwi_pasek = ColorRect.new()
	drzwi_pasek.color = Color(1.0, 0.4, 0.0, 1.0)
	drzwi_pasek.position = Vector2(760, 900)
	drzwi_pasek.size = Vector2(400, 30)
	hud.add_child(drzwi_pasek)
	
	drzwi_label = Label.new()
	drzwi_label.text = "Drzwi: 100%"
	drzwi_label.position = Vector2(900, 870)
	drzwi_label.set("theme_override_font_sizes/font_size", 20)
	drzwi_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	drzwi_label.set("theme_override_constants/outline_size", 4)
	drzwi_label.modulate = Color.WHITE
	hud.add_child(drzwi_label)

func _process(delta: float) -> void:
	if not gra_aktywna: return

	if minimapa_bg.visible:
		_odswiez_minimape()

	if label_zadanie.visible and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		label_zadanie.visible = false
		if label_skrzynka:
			label_skrzynka.visible = true

	if faza == "DRZWI":
		var trzyma_e = Input.is_key_pressed(KEY_E)
		if trzyma_e and gracz:
			rabanie_kat -= delta * 8.0
			if siekira_pivot: siekira_pivot.rotation = rabanie_kat
			rabanie_cooldown -= delta
			if rabanie_cooldown <= 0:
				rabanie_cooldown = 0.3
				_rabniecie_drzwi_tick()
		else:
			if siekira_pivot:
				siekira_pivot.rotation = lerp_angle(siekira_pivot.rotation, 0.0, delta * 3.0)
		return

	# Odliczanie czasu (nie zatrzymuje się po wyniesieniu - gramy dalej do zgaszenia pożarów)
	czas -= delta
	if label_czas:
		label_czas.text = "Czas: " + str(int(czas))
		if czas <= 30: label_czas.modulate = Color.RED
		else: label_czas.modulate = Color.WHITE

	if czas <= 0 and gra_aktywna:
		czas = 0
		przegrana()

	# Sprawdzanie dystansu do Sprzątacza (Poniżej 200px)
	if faza == "POZARY_I_SPRZATACZ" and is_instance_valid(sprzatacz_npc) and sprzatacz_npc.visible and gracz:
		var dystans = gracz.global_position.distance_to(sprzatacz_npc.global_position)
		if dystans < 200.0 and not gracz.ma_sprzatacza and not sprzatacz_uratowany:
			if label_skrzynka:
				label_skrzynka.text = "Wciśnij E aby wyprowadzić osobę z budynku"
				label_skrzynka.visible = true
		else:
			if label_skrzynka and not gracz.ma_sprzatacza:
				label_skrzynka.visible = false

	if faza == "POZARY_I_SPRZATACZ":
		czas_do_rozrostu -= delta
		if czas_do_rozrostu <= 0:
			czas_do_rozrostu = 5.0
			if ognie.size() > 0 and ognie.size() < 30:
				var losowy_ogien = ognie[randi() % ognie.size()]
				if is_instance_valid(losowy_ogien):
					var znaleziono_miejsce = false
					var nowa_pozycja = Vector2.ZERO
					for proba in range(5):
						var offset = Vector2(randf_range(-120, 120), randf_range(-120, 120))
						nowa_pozycja = losowy_ogien.position + offset
						if not _czy_pozycja_zablokowana(nowa_pozycja):
							znaleziono_miejsce = true
							break
					if znaleziono_miejsce:
						var nowy_ogien = OGIEN_SCENA.instantiate()
						nowy_ogien.position = nowa_pozycja
						add_child(nowy_ogien)
						ognie.append(nowy_ogien)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			minimapa_bg.visible = !minimapa_bg.visible
			if minimapa_bg.visible: _odswiez_minimape()
		elif minimapa_bg.visible:
			minimapa_bg.visible = false
	elif event is InputEventMouseButton and event.pressed:
		if minimapa_bg.visible:
			minimapa_bg.visible = false

func _rabniecie_drzwi_tick():
	if faza != "DRZWI" or not gracz: return
	var drzwi_pos = local_to_world(Vector2(7500, 1000))
	if gracz.global_position.distance_to(drzwi_pos) > 800: return

	drzwi_hp -= 1.0
	var procent = drzwi_hp / drzwi_max_hp
	if drzwi_pasek:
		drzwi_pasek.size.x = procent * 400.0
		drzwi_pasek.color = Color(1.0, procent * 0.6, 0.0, 1.0)
	if drzwi_label:
		drzwi_label.text = "Drzwi: " + str(int(procent * 100)) + "%"
	
	var cam = gracz.get_node_or_null("Camera2D")
	if cam:
		cam.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		get_tree().create_timer(0.1).timeout.connect(func(): if is_instance_valid(cam): cam.offset = Vector2.ZERO)

	if drzwi_hp <= 0:
		_drzwi_wyburzone()

func _drzwi_wyburzone():
	jest_rabanie = false
	if drzwi_pasek: drzwi_pasek.visible = false
	if drzwi_pasek_bg: drzwi_pasek_bg.visible = false
	if drzwi_label: drzwi_label.visible = false
	if siekira_pivot: siekira_pivot.visible = false

	var blokada = get_node_or_null("BlokadaDrzwi")
	if blokada: blokada.queue_free()

	_fade_out(0.5)
	await get_tree().create_timer(0.6).timeout

	var tlo = get_node_or_null("Tlo")
	if tlo: tlo.texture = MAP_TEX_OTWARTE
	minimapa_bg.texture = MAP_TEX_OTWARTE

	if gracz: gracz.global_position = local_to_world(Vector2(7500, 1100))
	_fade_in(0.8)

	await get_tree().create_timer(0.3).timeout
	_rozpocznij_faze_pozary()

func _rozpocznij_faze_pozary():
	faza = "POZARY_I_SPRZATACZ"
	czas = 300.0

	if label_czas: label_czas.visible = true
	label_zadanie.text = "ZGAŚ POŻARY I URATUJ STARSZĄ OSOBĘ!"
	label_zadanie.modulate = Color.YELLOW
	label_zadanie.visible = true
	
	# PUNKT 1: Usunąłem wymuszenie pozycji wektorem. Sprzątacz spawnuje się tam gdzie ustawiłeś go w 2D
	if sprzatacz_npc:
		sprzatacz_npc.visible = true

	for poz in pozycje_ogni:
		var ilosc = randi_range(1, 5)
		var spakowane_w_tej_strefie = 0
		var proby_strefy = 0
		while spakowane_w_tej_strefie < ilosc and proby_strefy < 15:
			proby_strefy += 1
			var offset = Vector2.ZERO
			if spakowane_w_tej_strefie > 0:
				offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
			var testowana_pozycja = local_to_world(poz) + offset
			if not _czy_pozycja_zablokowana(testowana_pozycja):
				var ogien = OGIEN_SCENA.instantiate()
				ogien.position = testowana_pozycja
				add_child(ogien)
				ognie.append(ogien)
				spakowane_w_tej_strefie += 1

	var strazak_npc = get_node_or_null("StrazakNPC")
	if strazak_npc: strazak_npc.aktywuj()

# PUNKT 3: Funkcja pomocnicza do wykonania efektu Fade podczas interakcji podnoszenia/opuszczania NPC
func wykonaj_interakcje_fade(akcja_callable: Callable):
	gra_aktywna = false # tymczasowa blokada mechaniki podczas przełączania
	_fade_out(0.3)
	await get_tree().create_timer(0.35).timeout
	
	akcja_callable.call() # wykonanie logiki podnoszenia / opuszczenia wewnątrz czarnego ekranu
	
	_fade_in(0.4)
	await get_tree().create_timer(0.4).timeout
	gra_aktywna = true

func zgaszono_ogien(ogien):
	if ognie.has(ogien):
		ognie.erase(ogien)
		_sprawdz_warunek_przejscia()

func wyniesiono_sprzatacza_do_wyjscia():
	sprzatacz_uratowany = true
	if label_skrzynka:
		label_skrzynka.text = "Osoba bezpieczna!"
		label_skrzynka.visible = true
		
		# PUNKT 2: Komunikat 'Osoba bezpieczna' znika maksymalnie po 3 sekundach
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(label_skrzynka) and label_skrzynka.text == "Osoba bezpieczna!":
				label_skrzynka.visible = false
		)
	_sprawdz_warunek_przejscia()

func _sprawdz_warunek_przejscia():
	if ognie.size() <= 0 and sprzatacz_uratowany and faza == "POZARY_I_SPRZATACZ":
		rozpocznij_faze_skrzynka()

func rozpocznij_faze_skrzynka():
	faza = "SKRZYNKA"
	_fade_out(0.3)
	await get_tree().create_timer(0.4).timeout
	_fade_in(0.5)
	label_zadanie.text = "ZNAJDŹ CZARNĄ SKRZYNKĘ!"
	label_zadanie.modulate = Color.RED
	label_zadanie.visible = true
	if label_skrzynka:
		label_skrzynka.text = "Znajdź czarną skrzynkę (żółte na mapie) i kliknij E"
		label_skrzynka.visible = false

	var skrzynka_area = Area2D.new()
	skrzynka_area.name = "CzarnaSkrzynka"
	skrzynka_area.add_to_group("skrzynka")
	skrzynka_area.position = local_to_world(Vector2(1638, 3072))
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

func podniesiono_skrzynke():
	if faza != "SKRZYNKA": return
	faza = "KONIEC"
	_fade_out(0.3)
	await get_tree().create_timer(0.4).timeout
	_fade_in(0.5)
	label_zadanie.text = "UCIEKAJ DO WYJŚCIA!"
	label_zadanie.visible = true
	label_zadanie.modulate = Color.AQUA
	if label_skrzynka:
		label_skrzynka.text = "Biegnij do wyjścia (niebieskie na mapie)"
		label_skrzynka.modulate = Color.AQUA
		label_skrzynka.visible = false

	var wyjscie_area = Area2D.new()
	wyjscie_area.name = "Wyjscie"
	wyjscie_area.add_to_group("wyjscie")
	wyjscie_area.position = local_to_world(Vector2(7500, 900))
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(150, 150)
	col.shape = shape
	wyjscie_area.add_child(col)
	var spr = Sprite2D.new()
	spr.modulate = Color.AQUA
	spr.texture = WYKRZYKNIK_TEX
	spr.scale = Vector2(3, 3)
	wyjscie_area.add_child(spr)
	inst_wyjscie = wyjscie_area
	add_child(wyjscie_area)

func ucieczka_udana():
	if faza == "KONIEC":
		gra_aktywna = false
		_fade_out(1.0)
		await get_tree().create_timer(1.2).timeout
		if has_node("HUD"): $HUD.visible = false
		_odtworz_cutscenke()

func przegrana():
	gra_aktywna = false
	if label_czas: label_czas.text = "PRZEGRANA!"
	label_zadanie.text = "CZAS MINĄŁ!"
	label_zadanie.modulate = Color.RED
	label_zadanie.visible = true
	_fade_out(2.0)
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func przegrana_spalenie():
	if not gra_aktywna: return
	gra_aktywna = false
	if label_czas: label_czas.text = "PRZEGRANA!"
	label_zadanie.text = "SPŁONĄŁEŚ!"
	label_zadanie.modulate = Color.RED
	label_zadanie.visible = true
	_fade_out(2.0)
	if get_tree():
		await get_tree().create_timer(3.0).timeout
		if get_tree(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _fade_in(duration: float):
	if not fade_rect: return
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, duration)

func _fade_out(duration: float):
	if not fade_rect: return
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, duration)

func local_to_world(local_pos: Vector2) -> Vector2:
	var tlo = get_node_or_null("Tlo")
	var tlo_pos = tlo.position if tlo else Vector2(285, 317)
	var tlo_scale = tlo.scale if tlo else Vector2(0.939, 0.812)
	return local_pos * tlo_scale + tlo_pos

func world_to_local(world_pos: Vector2) -> Vector2:
	var tlo = get_node_or_null("Tlo")
	var tlo_pos = tlo.position if tlo else Vector2(285, 317)
	var tlo_scale = tlo.scale if tlo else Vector2(0.939, 0.812)
	return (world_pos - tlo_pos) / tlo_scale

func _odswiez_minimape():
	for child in markers_node.get_children(): child.queue_free()
	var map_world_size = Vector2(8192, 4096)
	var tex_size = minimapa_bg.texture.get_size()

	var get_marker_pos = func(real_pos: Vector2) -> Vector2:
		# Przeliczamy pozycję ze świata na pozycję lokalną tła
		var pos_norm = world_to_local(real_pos) / map_world_size
		return (pos_norm * tex_size) - (tex_size / 2.0)

	for ogien in ognie:
		if is_instance_valid(ogien):
			var m = Sprite2D.new()
			m.texture = WYKRZYKNIK_TEX
			m.scale = Vector2(2.0, 2.0)
			m.z_index = 20
			m.position = get_marker_pos.call(ogien.position)
			markers_node.add_child(m)

	if gracz and is_instance_valid(gracz):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/graphics/Dot.png") if ResourceLoader.exists("res://assets/graphics/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.8, 0.8)
		m.modulate = Color.GREEN
		m.position = get_marker_pos.call(gracz.global_position)
		m.z_index = 20
		markers_node.add_child(m)

	if faza == "POZARY_I_SPRZATACZ" and is_instance_valid(sprzatacz_npc) and sprzatacz_npc.visible and not sprzatacz_uratowany:
		var m = Sprite2D.new()
		m.texture = preload("res://assets/graphics/Dot.png") if ResourceLoader.exists("res://assets/graphics/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.DEEP_PINK
		m.position = get_marker_pos.call(sprzatacz_npc.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	if faza == "SKRZYNKA" and is_instance_valid(inst_skrzynka):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/graphics/Dot.png") if ResourceLoader.exists("res://assets/graphics/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.YELLOW
		m.position = get_marker_pos.call(inst_skrzynka.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	if faza == "KONIEC" and is_instance_valid(inst_wyjscie):
		var m = Sprite2D.new()
		m.texture = preload("res://assets/graphics/Dot.png") if ResourceLoader.exists("res://assets/graphics/Dot.png") else WYKRZYKNIK_TEX
		m.scale = Vector2(0.5, 0.5)
		m.modulate = Color.AQUA
		m.position = get_marker_pos.call(inst_wyjscie.global_position)
		m.z_index = 10
		markers_node.add_child(m)

	if faza == "DRZWI":
		var m = Sprite2D.new()
		m.texture = WYKRZYKNIK_TEX
		m.scale = Vector2(3.0, 3.0)
		m.modulate = Color.ORANGE
		m.position = get_marker_pos.call(Vector2(7500, 700))
		m.z_index = 20
		markers_node.add_child(m)

func _dodaj_sciany_graniczne():
	var border = StaticBody2D.new()
	border.name = "GranicaMapy"
	var grubosc = 200.0
	var szer = 8192.0
	var wys = 4096.0
	var g = CollisionShape2D.new()
	g.shape = RectangleShape2D.new()
	g.shape.size = Vector2(szer + grubosc * 2, grubosc)
	g.position = Vector2(szer / 2, -grubosc / 2)
	border.add_child(g)
	var d = CollisionShape2D.new()
	d.shape = RectangleShape2D.new()
	d.shape.size = Vector2(szer + grubosc * 2, grubosc)
	d.position = Vector2(szer / 2, wys + grubosc / 2)
	border.add_child(d)
	var l = CollisionShape2D.new()
	l.shape = RectangleShape2D.new()
	l.shape.size = Vector2(grubosc, wys)
	l.position = Vector2(-grubosc / 2, wys / 2)
	border.add_child(l)
	var p = CollisionShape2D.new()
	p.shape = RectangleShape2D.new()
	p.shape.size = Vector2(grubosc, wys)
	p.position = Vector2(szer + grubosc / 2, wys / 2)
	border.add_child(p)
	add_child(border)

func _odtworz_cutscenke():
	video_player = VideoStreamPlayer.new()
	video_player.stream = load(VIDEO_PATH)
	video_player.expand = true
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.bus = "Master"
	
	audio_player = AudioStreamPlayer.new()
	if ResourceLoader.exists(AUDIO_PATH):
		audio_player.stream = load(AUDIO_PATH)
	audio_player.bus = "Master"
	
	var cv = CanvasLayer.new()
	cv.layer = 120
	add_child(cv)
	cv.add_child(video_player)
	cv.add_child(audio_player)
	
	video_player.finished.connect(_po_cutscence)
	video_player.play()
	if audio_player.stream: audio_player.play()
	
	var tw = create_tween()
	video_player.modulate.a = 0
	tw.tween_property(video_player, "modulate:a", 1.0, 0.5)

func _po_cutscence():
	if video_player: video_player.stop()
	if audio_player: audio_player.stop()
	_fade_out(1.0)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/scena_5.tscn")

func _czy_pozycja_zablokowana(pozycja: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	if not space_state: return false
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pozycja
	query.collision_mask = 1 
	var wyniki = space_state.intersect_point(query)
	return wyniki.size() > 0
