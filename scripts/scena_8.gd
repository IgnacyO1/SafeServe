extends Node2D

# ========================================================
#  SCENA 8 – BOSS FIGHT: GRACZ vs CYBERKRAB
# ========================================================

var gra_aktywna = false
var krab_hp = 100.0
var krab_max_hp = 100.0
var aktualna_faza = 1

# Referencje do node'ów (tworzone w _ready)
var gracz: CharacterBody2D = null
var krab: CharacterBody2D = null
var pasek_hp: ColorRect = null
var pasek_hp_bg: ColorRect = null
var label_hp: Label = null
var label_faza: Label = null
var label_info: Label = null
var fade_rect: ColorRect = null
var hud: CanvasLayer = null

# Tekstury
var TEX_TLO = load("res://assets/graphics/Scena8/tło_walki.png")
var TEX_KRAB = load("res://assets/graphics/Scena8/krab.png")
var TEX_GRACZ = load("res://assets/graphics/scena4_sritesheet_wyczyszczone-removebg-preview.png")
var TEX_SKOSY = load("res://assets/graphics/scena4_spritesheet_skosy_beztla.png.png") if ResourceLoader.exists("res://assets/graphics/scena4_spritesheet_skosy_beztla.png.png") else null

var SCRIPT_GRACZ = preload("res://scripts/gracz_scena8.gd")
var SCRIPT_KRAB = preload("res://scripts/krab.gd")

func _ready():
	# === TŁO ===
	var tlo = Sprite2D.new()
	tlo.texture = TEX_TLO
	tlo.centered = false
	# Skalowanie tła do 1920x1080
	if TEX_TLO:
		var tex_size = TEX_TLO.get_size()
		tlo.scale = Vector2(1920.0 / tex_size.x, 1080.0 / tex_size.y)
	tlo.z_index = -10
	add_child(tlo)

	# === GRACZ ===
	gracz = CharacterBody2D.new()
	gracz.set_script(SCRIPT_GRACZ)
	gracz.position = Vector2(300, 540)  # Lewa strona areny

	var gracz_sprite = Sprite2D.new()
	gracz_sprite.name = "Sprite2D"
	gracz_sprite.texture = TEX_GRACZ
	gracz_sprite.hframes = 2
	gracz_sprite.vframes = 2
	gracz_sprite.scale = Vector2(1.2, 1.2)
	gracz.add_child(gracz_sprite)

	# Sprite skosów (opcjonalny)
	if TEX_SKOSY:
		var skosy_sprite = Sprite2D.new()
		skosy_sprite.name = "SpriteSkosy"
		skosy_sprite.texture = TEX_SKOSY
		skosy_sprite.hframes = 2
		skosy_sprite.vframes = 2
		skosy_sprite.scale = Vector2(1.2, 1.2)
		skosy_sprite.visible = false
		gracz.add_child(skosy_sprite)

	var gracz_col = CollisionShape2D.new()
	var gracz_shape = RectangleShape2D.new()
	gracz_shape.size = Vector2(30, 50)
	gracz_col.shape = gracz_shape
	gracz.add_child(gracz_col)

	var punkt_strzalu = Marker2D.new()
	punkt_strzalu.name = "PunktStrzalu"
	punkt_strzalu.position = Vector2(40, 0)
	gracz.add_child(punkt_strzalu)

	add_child(gracz)

	# === KRAB (BOSS) ===
	krab = CharacterBody2D.new()
	krab.set_script(SCRIPT_KRAB)
	krab.position = Vector2(1500, 540)  # Prawa strona areny

	var krab_sprite = Sprite2D.new()
	krab_sprite.name = "Sprite2D"
	krab_sprite.texture = TEX_KRAB
	krab_sprite.scale = Vector2(0.4, 0.4)
	krab.add_child(krab_sprite)

	var krab_col = CollisionShape2D.new()
	var krab_shape = RectangleShape2D.new()
	krab_shape.size = Vector2(160, 100)
	krab_col.shape = krab_shape
	krab.add_child(krab_col)

	add_child(krab)
	krab.gracz_ref = gracz

	# === ŚCIANY ARENY (niewidoczne) ===
	_stworz_sciany_areny()

	# === HUD ===
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	# Fade rect
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 100
	hud.add_child(fade_rect)

	# Pasek HP kraba - tło
	pasek_hp_bg = ColorRect.new()
	pasek_hp_bg.color = Color(0.15, 0.15, 0.15, 0.85)
	pasek_hp_bg.position = Vector2(460, 20)
	pasek_hp_bg.size = Vector2(1000, 35)
	hud.add_child(pasek_hp_bg)

	# Pasek HP kraba - wypełnienie
	pasek_hp = ColorRect.new()
	pasek_hp.color = Color(0.0, 0.9, 0.0, 1.0)
	pasek_hp.position = Vector2(462, 22)
	pasek_hp.size = Vector2(996, 31)
	hud.add_child(pasek_hp)

	# Label HP
	label_hp = Label.new()
	label_hp.text = "⚡ CYBERKRAB ⚡"
	label_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_hp.position = Vector2(760, 22)
	label_hp.set("theme_override_font_sizes/font_size", 22)
	label_hp.set("theme_override_colors/font_color", Color.WHITE)
	label_hp.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_hp.set("theme_override_constants/outline_size", 4)
	hud.add_child(label_hp)

	# Label fazy
	label_faza = Label.new()
	label_faza.text = "FAZA 1"
	label_faza.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_faza.position = Vector2(910, 58)
	label_faza.set("theme_override_font_sizes/font_size", 16)
	label_faza.set("theme_override_colors/font_color", Color(1, 0.7, 0, 1))
	label_faza.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_faza.set("theme_override_constants/outline_size", 3)
	hud.add_child(label_faza)

	# Label informacyjny (na środku ekranu)
	label_info = Label.new()
	label_info.text = ""
	label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_info.set_anchors_preset(Control.PRESET_CENTER)
	label_info.set("theme_override_font_sizes/font_size", 52)
	label_info.set("theme_override_colors/font_color", Color(1, 0.3, 0.1, 1))
	label_info.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_info.set("theme_override_constants/outline_size", 6)
	label_info.visible = false
	hud.add_child(label_info)

	# === START GRY ===
	_fade_in(1.0)
	await get_tree().create_timer(0.5).timeout
	_pokaz_info("WALKA Z CYBERKRABEM!", 2.0)
	await get_tree().create_timer(2.5).timeout
	_pokaz_info("GOTOWY?", 1.0)
	await get_tree().create_timer(1.5).timeout
	_pokaz_info("WALCZ!", 1.0)
	await get_tree().create_timer(0.5).timeout
	gra_aktywna = true

func _process(delta):
	if not gra_aktywna:
		return
	_aktualizuj_pasek_hp()

# ============================================
#  SYSTEM HP I FAZ
# ============================================

func krab_trafiony(obrazenia: int):
	if not gra_aktywna:
		return
	krab_hp -= obrazenia
	krab_hp = max(krab_hp, 0)

	# Screen shake
	_screen_shake()

	# Flash kraba na biało
	if krab and is_instance_valid(krab):
		var spr = krab.get_node_or_null("Sprite2D")
		if spr:
			spr.modulate = Color(10, 10, 10, 1)  # Flash biały
			get_tree().create_timer(0.1).timeout.connect(func():
				if is_instance_valid(spr): spr.modulate = Color.WHITE)

	# Sprawdź fazy
	_sprawdz_faze()

	# Sprawdź śmierć kraba
	if krab_hp <= 0:
		_wygrana()

func _sprawdz_faze():
	var procent = krab_hp / krab_max_hp
	var nowa_faza = 1
	if procent <= 0.25:
		nowa_faza = 4
	elif procent <= 0.50:
		nowa_faza = 3
	elif procent <= 0.75:
		nowa_faza = 2

	if nowa_faza != aktualna_faza:
		aktualna_faza = nowa_faza
		if krab and is_instance_valid(krab) and krab.has_method("ustaw_faze"):
			krab.ustaw_faze(nowa_faza)

		# Efekt wizualny zmiany fazy
		label_faza.text = "FAZA " + str(nowa_faza)
		match nowa_faza:
			2:
				_pokaz_info("TELEPORTACJA AKTYWNA!", 1.5)
				label_faza.set("theme_override_colors/font_color", Color.YELLOW)
			3:
				_pokaz_info("KRAB WŚCIEKA SIĘ!", 1.5)
				label_faza.set("theme_override_colors/font_color", Color.ORANGE_RED)
			4:
				_pokaz_info("OSTATNIA FAZA!", 1.5)
				label_faza.set("theme_override_colors/font_color", Color.RED)

		# Krótki screen shake przy zmianie fazy
		_screen_shake(10.0)

func _aktualizuj_pasek_hp():
	if not pasek_hp:
		return
	var procent = krab_hp / krab_max_hp
	pasek_hp.size.x = procent * 996.0

	# Kolor paska: zielony → żółty → pomarańczowy → czerwony
	if procent > 0.75:
		pasek_hp.color = Color(0.0, 0.9, 0.0, 1.0)
	elif procent > 0.50:
		pasek_hp.color = Color(0.9, 0.9, 0.0, 1.0)
	elif procent > 0.25:
		pasek_hp.color = Color(0.9, 0.5, 0.0, 1.0)
	else:
		# Pulsowanie czerwieni w ostatniej fazie
		var pulse = abs(sin(Time.get_ticks_msec() * 0.005))
		pasek_hp.color = Color(0.9, pulse * 0.2, 0.0, 1.0)

# ============================================
#  GRACZ TRAFIONY = PRZEGRANA
# ============================================

func gracz_trafiony():
	if not gra_aktywna:
		return
	gra_aktywna = false

	# Screen shake mocny
	_screen_shake(20.0)

	# Czerwony flash ekranu
	var flash = ColorRect.new()
	flash.color = Color(1, 0, 0, 0.6)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 90
	hud.add_child(flash)

	var tw_flash = create_tween()
	tw_flash.tween_property(flash, "color:a", 0.0, 0.5)
	tw_flash.tween_callback(func(): flash.queue_free())

	_pokaz_info("PRZEGRANA!", 2.0)

	_fade_out(2.0)
	await get_tree().create_timer(3.0).timeout

	# --- PRZEJŚCIE PO PRZEGRANEJ ---
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	# OPCJA 2: Restart sceny (odkomentuj poniżej)
	#get_tree().reload_current_scene()

# ============================================
#  KRAB POKONANY = WYGRANA
# ============================================

func _wygrana():
	if not gra_aktywna:
		return
	gra_aktywna = false

	# Zniszcz kraba z efektem
	if krab and is_instance_valid(krab):
		var spr = krab.get_node_or_null("Sprite2D")
		if spr:
			var tw = create_tween()
			tw.tween_property(spr, "modulate", Color(1, 0, 0, 1), 0.3)
			tw.tween_property(spr, "scale", Vector2(0.6, 0.6), 0.5)
			tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.5)
			tw.tween_callback(func():
				if is_instance_valid(krab): krab.queue_free())

	# Efekty - partykuły eksplozji (proste kwadraty)
	if krab and is_instance_valid(krab):
		for i in range(20):
			var part = ColorRect.new()
			part.color = Color(randf_range(0.8, 1.0), randf_range(0.0, 0.3), 0.0, 1.0)
			part.size = Vector2(randf_range(8, 25), randf_range(8, 25))
			part.position = krab.global_position + Vector2(randf_range(-60, 60), randf_range(-40, 40))
			part.z_index = 50
			add_child(part)
			var tw_p = create_tween()
			tw_p.tween_property(part, "position", part.position + Vector2(randf_range(-200, 200), randf_range(-200, 200)), randf_range(0.5, 1.5))
			tw_p.parallel().tween_property(part, "modulate:a", 0.0, randf_range(0.5, 1.5))
			tw_p.tween_callback(func(): if is_instance_valid(part): part.queue_free())

	_pokaz_info("CYBERKRAB POKONANY!", 3.0)

	await get_tree().create_timer(3.5).timeout
	_fade_out(1.5)
	await get_tree().create_timer(2.0).timeout

	# --- PRZEJŚCIE PO WYGRANEJ ---
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	# OPCJA 2: Cutscenka (odkomentuj poniżej i podaj ścieżkę)
	#_odtworz_cutscenke("res://assets/Videos/cutscene_ending.ogv")
	# OPCJA 3: Następna scena / credits
	#get_tree().change_scene_to_file("res://scenes/credits.tscn")

# ============================================
#  EFEKTY WIZUALNE
# ============================================

func _fade_in(duration: float):
	if not fade_rect:
		return
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, duration)

func _fade_out(duration: float):
	if not fade_rect:
		return
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, duration)

func _pokaz_info(tekst: String, czas: float):
	if not label_info:
		return
	label_info.text = tekst
	label_info.visible = true
	label_info.modulate = Color.WHITE
	# Animacja pojawiania
	var tw = create_tween()
	tw.tween_property(label_info, "modulate:a", 1.0, 0.2)
	tw.tween_interval(czas - 0.4)
	tw.tween_property(label_info, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): label_info.visible = false)

func _screen_shake(intensity: float = 5.0):
	# Shake na fade_rect (przesunięcie HUD)
	if gracz and is_instance_valid(gracz):
		var original_pos = gracz.position
		var tw = create_tween()
		for i in range(5):
			tw.tween_property(gracz, "position",
				original_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)),
				0.03)
		tw.tween_property(gracz, "position", original_pos, 0.03)

# ============================================
#  ŚCIANY ARENY (niewidoczne)
# ============================================

func _stworz_sciany_areny():
	var border = StaticBody2D.new()
	border.name = "GraniceAreny"

	var grubosc = 100.0
	var szer = 1920.0
	var wys = 1080.0

	# Górna ściana
	var g = CollisionShape2D.new()
	g.shape = RectangleShape2D.new()
	g.shape.size = Vector2(szer + grubosc * 2, grubosc)
	g.position = Vector2(szer / 2, -grubosc / 2)
	border.add_child(g)

	# Dolna ściana
	var d = CollisionShape2D.new()
	d.shape = RectangleShape2D.new()
	d.shape.size = Vector2(szer + grubosc * 2, grubosc)
	d.position = Vector2(szer / 2, wys + grubosc / 2)
	border.add_child(d)

	# Lewa ściana
	var l = CollisionShape2D.new()
	l.shape = RectangleShape2D.new()
	l.shape.size = Vector2(grubosc, wys)
	l.position = Vector2(-grubosc / 2, wys / 2)
	border.add_child(l)

	# Prawa ściana
	var p = CollisionShape2D.new()
	p.shape = RectangleShape2D.new()
	p.shape.size = Vector2(grubosc, wys)
	p.position = Vector2(szer + grubosc / 2, wys / 2)
	border.add_child(p)

	add_child(border)

# ============================================
#  CUTSCENKA (zakomentowane - do użycia później)
# ============================================

#func _odtworz_cutscenke(path: String):
#	var video_player = VideoStreamPlayer.new()
#	video_player.stream = load(path)
#	video_player.expand = true
#	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
#	video_player.bus = "Master"
#	var cv = CanvasLayer.new()
#	cv.layer = 120
#	add_child(cv)
#	cv.add_child(video_player)
#	video_player.finished.connect(func():
#		video_player.stop()
#		_fade_out(1.0)
#		await get_tree().create_timer(1.0).timeout
#		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
#	video_player.play()
