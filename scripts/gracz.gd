extends CharacterBody2D

@onready var label_skrzynka = get_parent().get_node("HUD/LabelSkrzynka")
@onready var skrzynka_node = get_parent().get_node("CzarnaSkrzynka")

const SPEED = 250.0
const POCISK = preload("res://scenes/pocisk.tscn")
var ma_skrzynke = false
var przy_npc = null

func _ready():
	z_index = 10 # Ustawiamy gracza ZAWSZE nad mapą!
	# Nie szukamy już skrzynki na sztywno przy starcie, wygeneruje ją scena główna
	if skrzynka_node:
		skrzynka_node.visible = false
		if skrzynka_node.has_node("CollisionShape2D"):
			skrzynka_node.get_node("CollisionShape2D").disabled = true

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
	var aktualna_predkosc = SPEED
	if Input.is_action_pressed("ui_accept"):
		aktualna_predkosc = SPEED * 1.8
	velocity = direction * aktualna_predkosc
	move_and_slide()

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var pocisk = POCISK.instantiate()
			get_parent().add_child(pocisk)
			pocisk.global_position = $PunktStrzalu.global_position
			pocisk.direction = (get_global_mouse_position() - global_position).normalized()

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
				if label_skrzynka:
					label_skrzynka.text = "Znajdz czarna skrzynke!"
			elif not ma_skrzynke:
				var skrzynki = get_tree().get_nodes_in_group("skrzynka")
				for s in skrzynki:
					if global_position.distance_to(s.global_position) < 150:
						ma_skrzynke = true
						if scena_głowna.has_method("podniesiono_skrzynke"):
							scena_głowna.podniesiono_skrzynke()
						s.queue_free()
						if label_skrzynka:
							label_skrzynka.text = "Masz czarna skrzynke!"

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
