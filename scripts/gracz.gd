extends CharacterBody2D

@onready var label_skrzynka = get_parent().get_node_or_null("HUD/LabelSkrzynka")

const SPEED = 250.0
const POCISK = preload("res://scenes/pocisk.tscn")
var ma_skrzynke = false
var przy_npc = null

func _ready():
	z_index = 10 # Ustawiamy gracza ZAWSZE nad mapą!

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		# Ustawiamy klatkę animacji i pozycję PunktuStrzalu (gaśnicy) w zależności od kierunku ruchu
		if abs(direction.x) > abs(direction.y):
			if direction.x < 0:
				$Sprite2D.frame = 2 # Lewy dolny to w lewo
				$PunktStrzalu.position = Vector2(-20, 15)
			else:
				$Sprite2D.frame = 1 # Prawy górny to w prawo
				$PunktStrzalu.position = Vector2(20, 15)
		else:
			if direction.y < 0:
				$Sprite2D.frame = 0 # Lewy górny to w górę
				$PunktStrzalu.position = Vector2(15, 5)
			else:
				$Sprite2D.frame = 3 # Prawy dolny to w dół
				$PunktStrzalu.position = Vector2(-15, 15)

	var aktualna_predkosc = SPEED
	if Input.is_action_pressed("ui_accept"):
		aktualna_predkosc = SPEED * 1.8
	velocity = direction * aktualna_predkosc
	move_and_slide()

func _process(delta: float) -> void:
	pass # Usunięto look_at() - gracz teraz obraca się za pomocą sprite'ów (klatek)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var pocisk = POCISK.instantiate()
			get_parent().add_child(pocisk)
			pocisk.global_position = $PunktStrzalu.global_position
			pocisk.direction = (get_global_mouse_position() - pocisk.global_position).normalized()

	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed:
			var scena_głowna = get_parent()
			# Gasi pożar jeśli blisko
			if scena_głowna.has_method("zgaszono_ogien"):
				var wszystkie_ognie = get_tree().get_nodes_in_group("ogien")
				for ogien in wszystkie_ognie:
					if global_position.distance_to(ogien.global_position) < 80: # Zasięg gaszenia
						scena_głowna.zgaszono_ogien(ogien)
						ogien.queue_free()
						break # Gasi tylko 1 naraz

			if przy_npc != null:
				print("Zakładasz maskę na: ", przy_npc.name)
				print("Babcia uratowana! Teraz znajdź czarną skrzynkę!")
				if scena_głowna.has_method("uratowano_babcie"):
					scena_głowna.uratowano_babcie()
				przy_npc.queue_free()
				przy_npc = null
			elif not ma_skrzynke:
				var skrzynki = get_tree().get_nodes_in_group("skrzynka")
				for s in skrzynki:
					if global_position.distance_to(s.global_position) < 150:
						ma_skrzynke = true
						if scena_głowna.has_method("podniesiono_skrzynke"):
							scena_głowna.podniesiono_skrzynke()
						s.queue_free()

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("npc"):
		przy_npc = null

func _on_area_entered(area: Area2D) -> void:
	print("Weszla strefa: ", area.name)
	if area.is_in_group("npc"):
		przy_npc = area
		print("Babcia w zasiegu!")
	if area.is_in_group("wyjscie"):
		if ma_skrzynke:
			print("WYGRANA! Uciekles z serwerowni!")
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		else:
			print("Nie masz czarnej skrzynki! Wróc po nia!")
