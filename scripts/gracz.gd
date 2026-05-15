extends CharacterBody2D

@onready var label_skrzynka = get_parent().get_node_or_null("HUD/LabelSkrzynka")

const SPEED = 250.0
const POCISK = preload("res://scenes/pocisk.tscn")
var ma_skrzynke = false
var przy_npc = null

func _ready():
	z_index = 10

func _physics_process(delta: float) -> void:
	var scena = get_parent()
	var w_fazie_drzwi = scena.has_method("rabniecie_drzwi") and scena.get("faza") == "DRZWI"

	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	# Sprawdź czy mamy sprite skosów (tylko w scenie 3)
	var sprite_skosy = get_node_or_null("SpriteSkosy")
	var jest_skos = direction.x != 0 and direction.y != 0

	if direction != Vector2.ZERO:
		direction = direction.normalized()

		if jest_skos and sprite_skosy:
			# --- RUCH PO SKOSIE: użyj sprite'a skosów ---
			$Sprite2D.visible = false
			sprite_skosy.visible = true
			if direction.x < 0 and direction.y < 0:
				# Góra-lewo
				sprite_skosy.frame = 0
				$PunktStrzalu.position = Vector2(-15, -5)
			elif direction.x > 0 and direction.y < 0:
				# Góra-prawo
				sprite_skosy.frame = 1
				$PunktStrzalu.position = Vector2(15, -5)
			elif direction.x < 0 and direction.y > 0:
				# Dół-lewo
				sprite_skosy.frame = 3
				$PunktStrzalu.position = Vector2(-15, 15)
			elif direction.x > 0 and direction.y > 0:
				# Dół-prawo
				sprite_skosy.frame = 2
				$PunktStrzalu.position = Vector2(15, 15)
		else:
			# --- RUCH KARDYNALNY: użyj standardowego sprite'a ---
			$Sprite2D.visible = true
			if sprite_skosy:
				sprite_skosy.visible = false
			if abs(direction.x) > abs(direction.y):
				if direction.x < 0:
					$Sprite2D.frame = 2
					$PunktStrzalu.position = Vector2(-20, 15)
				else:
					$Sprite2D.frame = 1
					$PunktStrzalu.position = Vector2(20, 15)
			else:
				if direction.y < 0:
					$Sprite2D.frame = 0
					$PunktStrzalu.position = Vector2(15, 5)
				else:
					$Sprite2D.frame = 3
					$PunktStrzalu.position = Vector2(-15, 15)

	var aktualna_predkosc = SPEED
	if Input.is_action_pressed("ui_accept"):
		aktualna_predkosc = SPEED * 1.8
	velocity = direction * aktualna_predkosc
	move_and_slide()

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var scena = get_parent()
			# Nie strzelaj gaśnicą w fazie DRZWI
			if scena.get("faza") == "DRZWI":
				return
			var pocisk = POCISK.instantiate()
			get_parent().add_child(pocisk)
			pocisk.global_position = $PunktStrzalu.global_position
			pocisk.direction = (get_global_mouse_position() - pocisk.global_position).normalized()

	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed:
			var scena_głowna = get_parent()

			# W fazie DRZWI - nie rób nic (obsługa w _process sceny)
			if scena_głowna.get("faza") == "DRZWI":
				return

			# Gaszenie pożarów
			if scena_głowna.has_method("zgaszono_ogien"):
				var wszystkie_ognie = get_tree().get_nodes_in_group("ogien")
				for ogien in wszystkie_ognie:
					if global_position.distance_to(ogien.global_position) < 80:
						scena_głowna.zgaszono_ogien(ogien)
						ogien.queue_free()
						break

			# Babcia
			if przy_npc != null:
				print("Babcia uratowana!")
				if scena_głowna.has_method("uratowano_babcie"):
					scena_głowna.uratowano_babcie()
				przy_npc.queue_free()
				przy_npc = null
			# Skrzynka
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
	if area.is_in_group("npc"):
		przy_npc = area
	if area.is_in_group("wyjscie"):
		var scena = get_parent()
		if ma_skrzynke and scena.has_method("ucieczka_udana"):
			scena.ucieczka_udana()
