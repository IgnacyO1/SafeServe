extends CharacterBody2D

@onready var label_skrzynka = get_parent().get_node_or_null("HUD/LabelSkrzynka")
@onready var anim_sprite = $AnimatedSprite2D

const SPEED = 320.0
const POCISK = preload("res://scenes/pocisk.tscn")
var ma_skrzynke = false
var ma_sprzatacza = false  

var ostatni_kierunek_idle = "dol"

func _ready():
	z_index = 10
	anim_sprite.scale = Vector2(0.3, 0.3)
	anim_sprite.speed_scale = 3.0
	anim_sprite.play("strazak_idle_dol")

func _physics_process(delta: float) -> void:
	var scena = get_parent()
	if scena.get("gra_aktywna") == false:
		velocity = Vector2.ZERO
		_update_animations(Vector2.ZERO)
		move_and_slide()
		return

	if scena.get("minimapa_bg") != null and scena.minimapa_bg.visible:
		velocity = Vector2.ZERO
		_update_animations(Vector2.ZERO)
		move_and_slide()
		return

	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left"): direction.x -= 1
	if Input.is_action_pressed("ui_down"): direction.y += 1
	if Input.is_action_pressed("ui_up"): direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		$PunktStrzalu.position = direction * 40.0

	_update_animations(direction)

	var aktualna_predkosc = SPEED
	if Input.is_action_pressed("ui_accept"):
		aktualna_predkosc = SPEED * 1.8
	velocity = direction * aktualna_predkosc
	move_and_slide()

	# PUNKT 3: Obsługa opuszczania sprzątacza przy wyjściu z użyciem efektu Fade
	if ma_sprzatacza and not scena.sprzatacz_uratowany:
		var wyjscie_pos = Vector2(7500, 1100) 
		if scena.has_method("local_to_world"):
			wyjscie_pos = scena.local_to_world(wyjscie_pos)
		if global_position.distance_to(wyjscie_pos) < 250.0:
			if scena.has_method("wykonaj_interakcje_fade"):
				scena.wykonaj_interakcje_fade(func():
					ma_sprzatacza = false
					scena.wyniesiono_sprzatacza_do_wyjscia()
				)

func _update_animations(dir: Vector2):
	var anim_name = ""
	var stan = "strazak_noszenie_" if ma_sprzatacza else "strazak_"

	if dir == Vector2.ZERO:
		anim_name = stan + "idle_" + ostatni_kierunek_idle
	else:
		var angle = snappedf(dir.angle(), PI / 4)
		match angle:
			0.0: 
				anim_name = stan + "chodzenie_prawo"
				ostatni_kierunek_idle = "prawo"
			PI / 4.0: 
				anim_name = stan + "skos_dol_prawo"
				ostatni_kierunek_idle = "prawo"
			PI / 2.0: 
				anim_name = stan + "chodzenie_dol"
				ostatni_kierunek_idle = "dol"
			3.0 * PI / 4.0: 
				anim_name = stan + "skos_dol_lewo"
				ostatni_kierunek_idle = "lewo"
			PI, -PI: 
				anim_name = stan + "chodzenie_lewo"
				ostatni_kierunek_idle = "lewo"
			-3.0 * PI / 4.0: 
				anim_name = stan + "skos_gora_lewo"
				ostatni_kierunek_idle = "lewo"
			-PI / 2.0: 
				anim_name = stan + "chodzenie_gora"
				ostatni_kierunek_idle = "gora"
			-PI / 4.0: 
				anim_name = stan + "skos_gora_prawo"
				ostatni_kierunek_idle = "prawo"

	if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
		anim_sprite.play(anim_name)

func _unhandled_input(event: InputEvent) -> void:
	var scena = get_parent()
	if scena.get("gra_aktywna") == false: return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if scena.get("faza") == "DRZWI": return
			if ma_sprzatacza: return 
			
			var pocisk = POCISK.instantiate()
			get_parent().add_child(pocisk)
			pocisk.global_position = $PunktStrzalu.global_position
			pocisk.direction = (get_global_mouse_position() - pocisk.global_position).normalized()
			
			var space = get_world_2d().direct_space_state
			var ray = PhysicsRayQueryParameters2D.create(global_position, pocisk.global_position)
			ray.collide_with_areas = false
			ray.collide_with_bodies = true
			ray.collision_mask = 1
			if space.intersect_ray(ray):
				pocisk.queue_free()

	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed:
			var scena_głowna = get_parent()

			if scena_głowna.get("faza") == "DRZWI": return

			# PUNKT 3: Obsługa podnoszenia sprzątacza z użyciem efektu Fade
			if scena_głowna.get("faza") == "POZARY_I_SPRZATACZ" and not ma_sprzatacza and not scena_głowna.sprzatacz_uratowany:
				var npc_node = scena_głowna.sprzatacz_npc
				if is_instance_valid(npc_node) and global_position.distance_to(npc_node.global_position) < 200.0:
					if scena_głowna.has_method("wykonaj_interakcje_fade"):
						scena_głowna.wykonaj_interakcje_fade(func():
							ma_sprzatacza = true
							npc_node.queue_free() 
							if label_skrzynka:
								label_skrzynka.text = "Wynieś osobę do wyjścia (tam skąd przyszedłeś)!"
						)
					return

			# Czarna Skrzynka
			if scena_głowna.get("faza") == "SKRZYNKA" and not ma_skrzynke:
				var skrzynki = get_tree().get_nodes_in_group("skrzynka")
				for s in skrzynki:
					if global_position.distance_to(s.global_position) < 150:
						ma_skrzynke = true
						if scena_głowna.has_method("podniesiono_skrzynke"):
							scena_głowna.podniesiono_skrzynke()
						s.queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("wyjscie"):
		var scena = get_parent()
		if ma_skrzynke and scena.has_method("ucieczka_udana"):
			scena.ucieczka_udana()
	
	if area.is_in_group("ogien"):
		var scena = get_parent()
		if scena.has_method("przegrana_spalenie"): scena.przegrana_spalenie()
		elif scena.has_method("przegrana"): scena.przegrana()
