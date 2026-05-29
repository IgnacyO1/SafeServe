extends Node2D

# ========================================================
#  SCENA 8 – BOSS FIGHT MANAGER: GRACZ vs CYBERKRAB
# ========================================================

# Stan gry
var gra_aktywna = false
var krab_hp = 150.0
var krab_max_hp = 150.0
var aktualna_faza = 1
var gracz_zycia = 3
var gracz_niezniszczalny_timer = 0.0

# Referencje do węzłów w scenie (ułożone w edytorze)
@onready var gracz: CharacterBody2D = $Gracz
@onready var krab: CharacterBody2D = $Cyberkrab
@onready var tlo: Sprite2D = $Tlo
@onready var granice_areny: StaticBody2D = $GraniceAreny
@onready var muzyka: AudioStreamPlayer2D = $Muzyka
@onready var smierc_kraba_dzwiek: AudioStreamPlayer2D = $SmiercKrabaDzwiek

# Referencje do węzłów HUD (tworzone z kodu)
var hud: CanvasLayer = null
var pasek_hp: ColorRect = null
var pasek_hp_bg: ColorRect = null
var label_hp: Label = null
var label_faza: Label = null
var label_info: Label = null
var label_zycia: Label = null
var panel_zycia: ColorRect = null
var fade_rect: ColorRect = null

# Zmienne mechaniki lasera (dla Fazy 3 i 4)
var laser_timer = 0.0
var laser_active = false
var laser_warning = false
var laser_target_dir = Vector2.ZERO
var laser_duration = 3.0           # Całkowity czas ataku laserowego (wraz z ostrzeżeniem)
var laser_warning_duration = 0.6   # Czas ostrzeżenia (cienka linia)
var laser_attack_timer = 0.0
var laser_beam_line1: Line2D = null # Zewnętrzna warstwa (glowing orange-red)
var laser_beam_line2: Line2D = null # Wewnętrzny rdzeń (white-yellow)

func _ready():
	# Zapisz poziom w konfiguracji gry
	GameConfig.save_level("res://scenes/scena_8.tscn")
	
	# Upewnij się, że muzyka jest na starcie wyłączona (zagra po napisach)
	if muzyka and muzyka.playing:
		muzyka.stop()
	if muzyka:
		muzyka.volume_db = 0.0 # Zresetuj głośność po ewentualnej wcześniejszej wygranej/przegranej
		
	# === DOPASOWANIE POZYCJI STARTOWYCH ===
	
	# Gracz: Ustawienie na lewej stronie areny
	if gracz and is_instance_valid(gracz):
		gracz.position = Vector2(300, 720) # Środek areny po lewej stronie
		
		# Dynamiczne dodanie CollisionShape2D do gracza, jeśli go brakuje w scenie
		var gracz_col = gracz.get_node_or_null("CollisionShape2D")
		if not gracz_col:
			gracz_col = CollisionShape2D.new()
			gracz_col.name = "CollisionShape2D"
			var gracz_shape = RectangleShape2D.new()
			gracz_shape.size = Vector2(30, 50)
			gracz_col.shape = gracz_shape
			gracz.add_child(gracz_col)
		
		# Kamera: lekkie oddalenie + efekt chodzenia (drag)
		var cam = gracz.get_node_or_null("Camera2D")
		if cam:
			cam.zoom = Vector2(0.75, 0.75) # Widać więcej areny ale nie za dużo
			cam.position_smoothing_enabled = true
			cam.position_smoothing_speed = 4.0
			cam.drag_horizontal_enabled = true
			cam.drag_vertical_enabled = true
			cam.drag_left_margin = 0.15
			cam.drag_right_margin = 0.15
			cam.drag_top_margin = 0.15
			cam.drag_bottom_margin = 0.15
			
	# Boss (Cyberkrab): Wycentrowanie dzieci i przeniesienie na prawą stronę areny
	if krab and is_instance_valid(krab):
		var spr = krab.get_node_or_null("Sprite2D")
		var col = krab.get_node_or_null("CollisionShape2D")
		var target_pos = Vector2(2000, 720) # Prawa strona areny
		
		# Odczytanie pozycji lokalnej dzieci (gdy edytor zapisał np. offset 2000, 700 na dziecku zamiast rodzica)
		if spr and spr.position != Vector2.ZERO:
			target_pos = spr.position
			spr.position = Vector2.ZERO
		if col:
			col.position = Vector2.ZERO
			
		# Rodzic dostaje ostateczną, fizyczną pozycję bossa
		krab.position = target_pos
		
	# Tworzenie HUD z kodu
	_stworz_hud()
	
	# Szybka sekwencja intro (krótsze napisy)
	_fade_in(0.5)
	await get_tree().create_timer(0.2).timeout
	_pokaz_info("WALKA Z CYBERKRABEM!", 1.0)
	await get_tree().create_timer(1.2).timeout
	_pokaz_info("GOTOWY?", 0.6)
	await get_tree().create_timer(0.8).timeout
	_pokaz_info("WALCZ!", 0.6)
	await get_tree().create_timer(0.4).timeout
	
	# Włączenie gry i muzyki po napisach startowych
	gra_aktywna = true
	if muzyka and not muzyka.playing:
		muzyka.play()

func _process(delta):
	# Zawsze przetwarzaj timer niewrażliwości gracza
	if gracz_niezniszczalny_timer > 0.0:
		gracz_niezniszczalny_timer -= delta
		# Miganie sprita gracza jako feedback niewrażliwości
		if gracz and is_instance_valid(gracz):
			var gracz_sprite = gracz.get_node_or_null("AnimatedSprite2D")
			if gracz_sprite:
				gracz_sprite.visible = (sin(Time.get_ticks_msec() * 0.05) > 0.0)
	else:
		if gracz and is_instance_valid(gracz):
			var gracz_sprite = gracz.get_node_or_null("AnimatedSprite2D")
			if gracz_sprite and not gracz_sprite.visible:
				gracz_sprite.visible = true

	if not gra_aktywna:
		return
		
	_aktualizuj_pasek_hp()
	_zarzadzaj_laserem(delta)

func _stworz_hud():
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	
	# Czarna nakładka fade (pełny ekran 1920x1080)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.size = Vector2(1920, 1080)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 100
	hud.add_child(fade_rect)
	
	# Tło paska HP
	pasek_hp_bg = ColorRect.new()
	pasek_hp_bg.color = Color(0.15, 0.15, 0.15, 0.85)
	pasek_hp_bg.position = Vector2(460, 40)
	pasek_hp_bg.size = Vector2(1000, 35)
	hud.add_child(pasek_hp_bg)
	
	# Pasek HP kraba (zielony początkowo)
	pasek_hp = ColorRect.new()
	pasek_hp.color = Color(0.0, 0.9, 0.0, 1.0)
	pasek_hp.position = Vector2(462, 42)
	pasek_hp.size = Vector2(996, 31)
	hud.add_child(pasek_hp)
	
	# Nazwa Bossa
	label_hp = Label.new()
	label_hp.text = "⚡ CYBERKRAB ⚡"
	label_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_hp.position = Vector2(460, 10)
	label_hp.size = Vector2(1000, 30)
	label_hp.set("theme_override_font_sizes/font_size", 22)
	label_hp.set("theme_override_colors/font_color", Color.WHITE)
	label_hp.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_hp.set("theme_override_constants/outline_size", 4)
	hud.add_child(label_hp)
	
	# Label aktualnej fazy
	label_faza = Label.new()
	label_faza.text = "FAZA 1"
	label_faza.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_faza.position = Vector2(460, 80)
	label_faza.size = Vector2(1000, 30)
	label_faza.set("theme_override_font_sizes/font_size", 16)
	label_faza.set("theme_override_colors/font_color", Color(0.0, 0.9, 0.0, 1.0))
	label_faza.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_faza.set("theme_override_constants/outline_size", 3)
	hud.add_child(label_faza)
	
	# Panel żyć gracza (top-left)
	panel_zycia = ColorRect.new()
	panel_zycia.color = Color(0.1, 0.1, 0.1, 0.6)
	panel_zycia.position = Vector2(30, 30)
	panel_zycia.size = Vector2(180, 50)
	hud.add_child(panel_zycia)
	
	label_zycia = Label.new()
	label_zycia.text = "❤️ ŻYCIA: " + str(gracz_zycia)
	label_zycia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_zycia.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_zycia.size = Vector2(180, 50)
	label_zycia.set("theme_override_font_sizes/font_size", 20)
	label_zycia.set("theme_override_colors/font_color", Color.WHITE)
	label_zycia.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_zycia.set("theme_override_constants/outline_size", 3)
	panel_zycia.add_child(label_zycia)
	
	# Label informacyjny na środku ekranu
	label_info = Label.new()
	label_info.text = ""
	label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_info.position = Vector2(0, 440)
	label_info.size = Vector2(1920, 200)
	label_info.set("theme_override_font_sizes/font_size", 56)
	label_info.set("theme_override_colors/font_color", Color(1, 0.3, 0.1, 1))
	label_info.set("theme_override_colors/font_outline_color", Color.BLACK)
	label_info.set("theme_override_constants/outline_size", 8)
	label_info.visible = false
	hud.add_child(label_info)

# ============================================
# System HP, Faz i Lasera
# ============================================

func krab_trafiony(obrazenia: int):
	if not gra_aktywna:
		return
	krab_hp -= obrazenia
	krab_hp = max(krab_hp, 0.0)
	
	# Szybki screen shake
	_screen_shake(6.0)
	
	# Biały flash sprita bossa
	if krab and is_instance_valid(krab):
		var spr = krab.get_node_or_null("Sprite2D")
		if spr:
			spr.modulate = Color(10, 10, 10, 1)
			var tw_flash = create_tween()
			tw_flash.tween_interval(0.1)
			tw_flash.tween_callback(func(): if is_instance_valid(spr): spr.modulate = Color.WHITE)
			
	# Sprawdź zmianę fazy
	_sprawdz_faze()
	
	# Sprawdź śmierć
	if krab_hp <= 0.0:
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
			
		# Zmiana opisu i koloru fazy w HUD
		label_faza.text = "FAZA " + str(nowa_faza)
		match nowa_faza:
			2:
				_pokaz_info("TELEPORTACJA AKTYWNA!", 1.5)
				label_faza.set("theme_override_colors/font_color", Color.YELLOW)
			3:
				_pokaz_info("KRAB WŚCIEKA SIĘ! (LASER AKTYWNY)", 1.5)
				label_faza.set("theme_override_colors/font_color", Color.ORANGE_RED)
				laser_timer = 0.0
			4:
				_pokaz_info("OSTATNIA FAZA! (MOCNIEJSZY LASER!)", 1.5)
				label_faza.set("theme_override_colors/font_color", Color.RED)
				
		_screen_shake(12.0)

func _aktualizuj_pasek_hp():
	if not pasek_hp:
		return
	var procent = krab_hp / krab_max_hp
	pasek_hp.size.x = procent * 996.0
	
	if procent > 0.75:
		pasek_hp.color = Color(0.0, 0.9, 0.0, 1.0) # Zielony
	elif procent > 0.50:
		pasek_hp.color = Color(0.9, 0.9, 0.0, 1.0) # Żółty
	elif procent > 0.25:
		pasek_hp.color = Color(0.9, 0.5, 0.0, 1.0) # Pomarańczowy
	else:
		# Pulsowanie na czerwono w ostatniej fazie
		var pulse = abs(sin(Time.get_ticks_msec() * 0.01))
		pasek_hp.color = Color(0.95, pulse * 0.15, 0.0, 1.0)

# Zarządzanie maszyną stanów lasera
func _zarzadzaj_laserem(delta):
	# Laser aktywny jest tylko w fazach 3 oraz 4
	if aktualna_faza < 3:
		return
		
	if not laser_warning and not laser_active:
		laser_timer += delta
		if laser_timer >= 3.0:
			_wystrzel_laser()
			
	elif laser_warning:
		laser_attack_timer += delta
		# Aktualizuj pozycję i kierunek linii ostrzegawczej z Cyberkraba do gracza
		if krab and is_instance_valid(krab) and gracz and is_instance_valid(gracz):
			var start_pos = krab.global_position
			var end_pos = start_pos + laser_target_dir * 3000.0
			if is_instance_valid(laser_beam_line1):
				laser_beam_line1.points = [start_pos, end_pos]
				
		if laser_attack_timer >= laser_warning_duration:
			_aktywuj_promien_lasera()
			
	elif laser_active:
		laser_attack_timer += delta
		
		if krab and is_instance_valid(krab) and gracz and is_instance_valid(gracz):
			var start_pos = krab.global_position
			# Oblicz kierunek do gracza i powoli go koryguj (namierzanie)
			var target_now = (gracz.global_position - start_pos).normalized()
			# W fazie 4 namierza szybciej (slerp 2.5) niż w fazie 3 (slerp 1.5)
			var slerp_speed = 2.5 if aktualna_faza == 4 else 1.5
			laser_target_dir = laser_target_dir.slerp(target_now, slerp_speed * delta).normalized()
			
			var end_pos = start_pos + laser_target_dir * 3000.0
			
			# Aktualizacja linii sprita lasera
			if is_instance_valid(laser_beam_line1):
				laser_beam_line1.points = [start_pos, end_pos]
			if is_instance_valid(laser_beam_line2):
				laser_beam_line2.points = [start_pos, end_pos]
				
			# Matematyczna kolizja: odległość gracza do odcinka lasera
			var closest_point = Geometry2D.get_closest_point_to_segment(gracz.global_position, start_pos, end_pos)
			var dist = gracz.global_position.distance_to(closest_point)
			
			# Szerokość lasera: Faza 4 = 35px, Faza 3 = 25px. Player radius = 20px
			var laser_w = 35.0 if aktualna_faza == 4 else 25.0
			if dist < (20.0 + laser_w / 2.0):
				gracz_trafiony()
				
			# Drganie ekranu podczas aktywnego lasera
			_screen_shake(2.0)
			
		if laser_attack_timer >= laser_duration:
			_wylacz_laser()

func _wystrzel_laser():
	laser_warning = true
	laser_attack_timer = 0.0
	
	if krab and is_instance_valid(krab) and gracz and is_instance_valid(gracz):
		laser_target_dir = (gracz.global_position - krab.global_position).normalized()
	else:
		laser_target_dir = Vector2.LEFT
		
	# Tworzenie czerwonej linii namierzającej (ostrzeżenie)
	laser_beam_line1 = Line2D.new()
	laser_beam_line1.width = 3.0
	laser_beam_line1.default_color = Color(1.0, 0.0, 0.0, 0.5)
	laser_beam_line1.z_index = 5
	add_child(laser_beam_line1)

func _aktywuj_promien_lasera():
	laser_warning = false
	laser_active = true
	
	# Usunięcie linii ostrzegawczej
	if is_instance_valid(laser_beam_line1):
		laser_beam_line1.queue_free()
		
	_screen_shake(15.0)
	
	# Promień zewnętrzny (ognisty pomarańcz)
	laser_beam_line1 = Line2D.new()
	laser_beam_line1.width = 35.0 if aktualna_faza == 4 else 25.0
	laser_beam_line1.default_color = Color(1.0, 0.3, 0.0, 0.9)
	laser_beam_line1.z_index = 6
	add_child(laser_beam_line1)
	
	# Promień wewnętrzny (biały gorący rdzeń)
	laser_beam_line2 = Line2D.new()
	laser_beam_line2.width = 12.0 if aktualna_faza == 4 else 8.0
	laser_beam_line2.default_color = Color(1.0, 1.0, 1.0, 1.0)
	laser_beam_line2.z_index = 7
	add_child(laser_beam_line2)

func _wylacz_laser():
	laser_warning = false
	laser_active = false
	laser_timer = 0.0
	
	if is_instance_valid(laser_beam_line1):
		laser_beam_line1.queue_free()
	if is_instance_valid(laser_beam_line2):
		laser_beam_line2.queue_free()

# ============================================
# Obrażenia Gracza
# ============================================

func gracz_trafiony():
	if not gra_aktywna or gracz_niezniszczalny_timer > 0.0:
		return
		
	gracz_zycia -= 1
	if label_zycia:
		label_zycia.text = "❤️ ŻYCIA: " + str(gracz_zycia)
		
	if gracz_zycia > 0:
		# Gracz przeżył, odpala niewrażliwość
		gracz_niezniszczalny_timer = 1.5
		
		# Czerwony flash uderzenia
		var flash = ColorRect.new()
		flash.color = Color(1, 0, 0, 0.4)
		flash.size = Vector2(1920, 1080)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.z_index = 90
		hud.add_child(flash)
		
		var tw_flash = create_tween()
		tw_flash.tween_property(flash, "color:a", 0.0, 0.4)
		tw_flash.tween_callback(func(): flash.queue_free())
		
		_screen_shake(15.0)
	else:
		# Przegrana
		gra_aktywna = false
		_wylacz_laser()
		
		# Zatrzymanie muzyki z fade outem
		if muzyka and muzyka.playing:
			var tw_music = create_tween()
			tw_music.tween_property(muzyka, "volume_db", -80.0, 1.5)
			
		# Silny screen shake
		_screen_shake(30.0)
		
		# Trwały czerwony flash
		var flash = ColorRect.new()
		flash.color = Color(1.0, 0.0, 0.0, 0.7)
		flash.size = Vector2(1920, 1080)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.z_index = 90
		hud.add_child(flash)
		
		var tw_flash = create_tween()
		tw_flash.tween_property(flash, "color:a", 0.3, 1.0)
		
		_pokaz_info("PRZEGRANA!", 3.0)
		_fade_out(2.5)
		
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ============================================
# Śmierć Bossa = Wygrana (Super Wybuchowa)
# ============================================

func _wygrana():
	if not gra_aktywna:
		return
	gra_aktywna = false
	_wylacz_laser()
	
	# Fading HUD
	var tw_hud = create_tween()
	if pasek_hp: tw_hud.tween_property(pasek_hp, "modulate:a", 0.0, 0.5)
	if pasek_hp_bg: tw_hud.parallel().tween_property(pasek_hp_bg, "modulate:a", 0.0, 0.5)
	if label_hp: tw_hud.parallel().tween_property(label_hp, "modulate:a", 0.0, 0.5)
	if label_faza: tw_hud.parallel().tween_property(label_faza, "modulate:a", 0.0, 0.5)
	if panel_zycia: tw_hud.parallel().tween_property(panel_zycia, "modulate:a", 0.0, 0.5)
	
	# Zapamiętaj pozycję Cyberkraba na wybuchy
	var krab_pos = Vector2(960, 540)
	if krab and is_instance_valid(krab):
		krab_pos = krab.global_position
		krab.set_physics_process(false)
		
	# Wyłączenie muzyki z szybkim fade outem
	if muzyka and muzyka.playing:
		var tw_music = create_tween()
		tw_music.tween_property(muzyka, "volume_db", -80.0, 1.0)
		
	if smierc_kraba_dzwiek:
		smierc_kraba_dzwiek.play()
		
	# === FAZA 1: SILNA AGONIA (1.5s) ===
	if krab and is_instance_valid(krab):
		var spr = krab.get_node_or_null("Sprite2D")
		if spr:
			var tw_agonia = create_tween()
			for i in range(25): # Drgawki
				var offset = Vector2(randf_range(-20.0, 20.0), randf_range(-15.0, 15.0))
				tw_agonia.tween_property(krab, "position", krab_pos + offset, 0.04)
				if i % 2 == 0:
					tw_agonia.parallel().tween_property(spr, "modulate", Color(6, 0.1, 0.1, 1), 0.04)
				else:
					tw_agonia.parallel().tween_property(spr, "modulate", Color(1, 1, 1, 1), 0.04)
			tw_agonia.tween_property(krab, "position", krab_pos, 0.05)
			tw_agonia.tween_property(spr, "modulate", Color(4, 0.0, 0.0, 1), 0.2)
			await tw_agonia.finished
			
	# === FAZA 2: SLOW-MOTION + GIGANTYCZNE EKSPLOZJE (2.0s) ===
	Engine.time_scale = 0.4
	
	# Seria 8 eksplozji wokół kraba z dużym screen shake'iem
	for i in range(8):
		var exp_offset = Vector2(randf_range(-130, 130), randf_range(-90, 90))
		_spawn_eksplozja(krab_pos + exp_offset, randf_range(45.0, 80.0))
		_screen_shake(18.0)
		await get_tree().create_timer(0.12).timeout # Czas z uwzględnieniem slow-mo
		
	# === FAZA 3: CENTRALNY ULTRA-BLAST + BIAŁY BŁYSK ===
	Engine.time_scale = 0.15 # Prawie zatrzymanie czasu na kulminację
	
	var white_flash = ColorRect.new()
	white_flash.color = Color(1, 1, 1, 0)
	white_flash.size = Vector2(1920, 1080)
	white_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	white_flash.z_index = 95
	hud.add_child(white_flash)
	
	var tw_flash = create_tween().set_ease(Tween.EASE_OUT)
	tw_flash.tween_property(white_flash, "color:a", 1.0, 0.1)
	
	# Zniknięcie sprita bossa pod wpływem blasku
	if krab and is_instance_valid(krab):
		var spr = krab.get_node_or_null("Sprite2D")
		if spr:
			var tw_die = create_tween()
			tw_die.tween_property(spr, "modulate", Color(12, 12, 12, 1), 0.1)
			tw_die.tween_property(spr, "modulate:a", 0.0, 0.05)
			
	await get_tree().create_timer(0.12).timeout
	
	# Gigantyczny wybuch centralny i ekstremalny wstrząs kamery
	_spawn_eksplozja(krab_pos, 220.0)
	_screen_shake(55.0) # Ekstremalny wstrząs
	
	# === FAZA 4: ROZPRASZANIE CZĄSTECZEK (SLOW-MOTION) ===
	Engine.time_scale = 0.5
	
	# Rozchodzący się pierścień ognia
	var ring = ColorRect.new()
	ring.color = Color(1.0, 0.5, 0.1, 0.8)
	ring.size = Vector2(20, 20)
	ring.position = krab_pos - Vector2(10, 10)
	ring.pivot_offset = Vector2(10, 10)
	ring.z_index = 55
	add_child(ring)
	
	var tw_ring = create_tween()
	tw_ring.tween_property(ring, "scale", Vector2(120, 120), 0.6)
	tw_ring.parallel().tween_property(ring, "modulate:a", 0.0, 0.6)
	tw_ring.tween_callback(func(): if is_instance_valid(ring): ring.queue_free())
	
	# Rozbłysk 40 gwiazd
	for i in range(40):
		var angle = (TAU / 40.0) * i + randf_range(-0.15, 0.15)
		var dist = randf_range(300, 700)
		var target_pos = krab_pos + Vector2(cos(angle), sin(angle)) * dist
		var size = randf_range(6, 24)
		
		var part = ColorRect.new()
		var kolory = [
			Color(1.0, 0.7, 0.1, 1.0),
			Color(1.0, 0.95, 0.3, 1.0),
			Color(1.0, 0.2, 0.0, 1.0),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(0.9, 0.4, 0.0, 1.0)
		]
		part.color = kolory[randi() % kolory.size()]
		part.size = Vector2(size, size)
		part.position = krab_pos - Vector2(size/2.0, size/2.0)
		part.pivot_offset = Vector2(size/2.0, size/2.0)
		part.rotation = randf_range(0.0, TAU)
		part.z_index = 52
		add_child(part)
		
		var flight_time = randf_range(0.5, 1.5)
		var tw_p = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tw_p.tween_property(part, "position", target_pos, flight_time)
		tw_p.parallel().tween_property(part, "rotation", part.rotation + randf_range(-4, 4), flight_time)
		tw_p.parallel().tween_property(part, "scale", Vector2(0.1, 0.1), flight_time)
		tw_p.parallel().tween_property(part, "modulate:a", 0.0, flight_time)
		tw_p.tween_callback(func(): if is_instance_valid(part): part.queue_free())
		
	# Iskry wylatujące losowo
	for i in range(30):
		var spark = ColorRect.new()
		spark.color = Color(1.0, 1.0, 0.8, 1.0)
		spark.size = Vector2(4, 4)
		spark.position = krab_pos
		spark.z_index = 54
		add_child(spark)
		var angle = randf_range(0.0, TAU)
		var dist = randf_range(200, 800)
		var tw_i = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw_i.tween_property(spark, "position", krab_pos + Vector2(cos(angle), sin(angle)) * dist, randf_range(0.4, 1.0))
		tw_i.parallel().tween_property(spark, "modulate:a", 0.0, randf_range(0.4, 1.0))
		tw_i.tween_callback(func(): if is_instance_valid(spark): spark.queue_free())
		
	# Usuń kraba z gry
	if krab and is_instance_valid(krab):
		krab.queue_free()
		
	# Powolne gaszenie białej kliszy
	await get_tree().create_timer(0.4).timeout
	var tw_flash_out = create_tween()
	tw_flash_out.tween_property(white_flash, "color:a", 0.0, 1.2)
	tw_flash_out.tween_callback(func(): if is_instance_valid(white_flash): white_flash.queue_free())
	
	# === FAZA 5: POWRÓT DO NORMY + NAPIS WYGRANEJ ===
	var tw_time = create_tween()
	tw_time.tween_method(func(v): Engine.time_scale = v, Engine.time_scale, 1.0, 0.8)
	await tw_time.finished
	
	# Upewnienie się na 100%
	Engine.time_scale = 1.0
	
	_pokaz_info("CYBERKRAB POKONANY!", 3.0)
	await get_tree().create_timer(3.5).timeout
	
	_fade_out(1.5)
	await get_tree().create_timer(2.0).timeout
	
	# Powrót do menu głównego
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Pomocnicze generowanie cząstek eksplozji
func _spawn_eksplozja(pos: Vector2, size: float):
	# Główna kula ognia
	var fire = ColorRect.new()
	fire.color = Color(1.0, 0.8, 0.1, 0.95)
	fire.size = Vector2(size, size)
	fire.position = pos - Vector2(size/2.0, size/2.0)
	fire.pivot_offset = Vector2(size/2.0, size/2.0)
	fire.z_index = 53
	add_child(fire)
	
	var tw1 = create_tween()
	tw1.tween_property(fire, "scale", Vector2(2.8, 2.8), 0.18)
	tw1.parallel().tween_property(fire, "modulate", Color(0.9, 0.1, 0.0, 0.8), 0.18)
	tw1.tween_property(fire, "scale", Vector2(3.8, 3.8), 0.25)
	tw1.parallel().tween_property(fire, "modulate:a", 0.0, 0.25)
	tw1.tween_callback(func(): if is_instance_valid(fire): fire.queue_free())
	
	# Obwódka fali uderzeniowej
	var shock = ColorRect.new()
	shock.color = Color(1.0, 1.0, 0.6, 0.6)
	shock.size = Vector2(size * 0.7, size * 0.7)
	shock.position = pos - Vector2(size * 0.35, size * 0.35)
	shock.pivot_offset = Vector2(size * 0.35, size * 0.35)
	shock.z_index = 54
	add_child(shock)
	
	var tw2 = create_tween()
	tw2.tween_property(shock, "scale", Vector2(4.2, 4.2), 0.15)
	tw2.parallel().tween_property(shock, "modulate:a", 0.0, 0.3)
	tw2.tween_callback(func(): if is_instance_valid(shock): shock.queue_free())

# ============================================
# Efekty i Przejścia
# ============================================

func _fade_in(duration: float):
	if not fade_rect: return
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, duration)

func _fade_out(duration: float):
	if not fade_rect: return
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, duration)

func _pokaz_info(text: String, duration: float):
	if not label_info: return
	label_info.text = text
	label_info.visible = true
	label_info.modulate.a = 0.0
	
	var tw = create_tween()
	tw.tween_property(label_info, "modulate:a", 1.0, 0.25)
	tw.tween_interval(duration - 0.5)
	tw.tween_property(label_info, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): label_info.visible = false)

func _screen_shake(intensity: float = 5.0):
	var camera = null
	if gracz and is_instance_valid(gracz):
		camera = gracz.get_node_or_null("Camera2D")
		
	if camera:
		var original_offset = camera.offset
		var tw = create_tween()
		for i in range(8):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			tw.tween_property(camera, "offset", offset, 0.03)
		tw.tween_property(camera, "offset", original_offset, 0.03)
	else:
		# Fallback: zatrzęś całą sceną
		var original_pos = position
		var tw = create_tween()
		for i in range(8):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			tw.tween_property(self, "position", original_pos + offset, 0.03)
		tw.tween_property(self, "position", original_pos, 0.03)
