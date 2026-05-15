extends CharacterBody2D

@onready var label_skrzynka = get_parent().get_node_or_null("HUD/LabelSkrzynka")
@onready var sprite = $Sprite2D

const SPEED = 250.0
const POCISK = preload("res://scenes/pocisk.tscn")
var ma_skrzynke = false
var przy_npc = null

var anim_timer = 0.0
var anim_speed = 0.15
var current_anim_frames = 1
var current_frame_idx = 0
var last_dir_str = "down"
var last_state = "idle"

var textures = {
	"idle": {
		"up": preload("res://assets/graphics/scena3_animacja_ruchu/idle_gora.png"),
		"down": preload("res://assets/graphics/scena3_animacja_ruchu/idle_dol.png"),
		"left": preload("res://assets/graphics/scena3_animacja_ruchu/idle_lewo.png"),
		"right": preload("res://assets/graphics/scena3_animacja_ruchu/idle_prawo.png"),
		"up_left": preload("res://assets/graphics/scena3_animacja_ruchu/idle_lewo.png"),
		"up_right": preload("res://assets/graphics/scena3_animacja_ruchu/idle_prawo.png"),
		"down_left": preload("res://assets/graphics/scena3_animacja_ruchu/idle_lewo.png"),
		"down_right": preload("res://assets/graphics/scena3_animacja_ruchu/idle_prawo.png")
	},
	"walk": {
		"up": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_gora.png"),
		"down": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_dol.png"),
		"left": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_lewo1.png"),
		"right": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_prawover1.png"),
		"up_left": preload("res://assets/graphics/scena3_animacja_ruchu/skos_gora_lewo.png"),
		"up_right": preload("res://assets/graphics/scena3_animacja_ruchu/skos_gora_prawo.png"),
		"down_left": preload("res://assets/graphics/scena3_animacja_ruchu/skos_dol_lewo.png"),
		"down_right": preload("res://assets/graphics/scena3_animacja_ruchu/skos_dol_prawo.png")
	}
}

var frame_counts = {
	"idle": 1,
	"walk_up": 4, "walk_down": 4,
	"walk_left": 3, "walk_right": 3,
	"walk_up_left": 2, "walk_up_right": 2,
	"walk_down_left": 2, "walk_down_right": 2
}

func _ready():
	z_index = 10
	set_animation("idle", "down")

func set_animation(state: String, dir_str: String):
	var tex = textures[state][dir_str]
	if sprite.texture != tex:
		sprite.texture = tex
		var frames_count = 1
		if state == "walk":
			frames_count = frame_counts["walk_" + dir_str]
		sprite.hframes = frames_count
		sprite.vframes = 1
		current_anim_frames = frames_count
		current_frame_idx = 0
		sprite.frame = 0
		anim_timer = 0.0

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

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	var state = "idle"
	var dir_str = last_dir_str

	if direction != Vector2.ZERO:
		state = "walk"
		if direction.x < -0.1 and direction.y < -0.1:
			dir_str = "up_left"
			$PunktStrzalu.position = Vector2(-15, -5)
		elif direction.x > 0.1 and direction.y < -0.1:
			dir_str = "up_right"
			$PunktStrzalu.position = Vector2(15, -5)
		elif direction.x < -0.1 and direction.y > 0.1:
			dir_str = "down_left"
			$PunktStrzalu.position = Vector2(-15, 15)
		elif direction.x > 0.1 and direction.y > 0.1:
			dir_str = "down_right"
			$PunktStrzalu.position = Vector2(15, 15)
		elif direction.x < -0.1:
			dir_str = "left"
			$PunktStrzalu.position = Vector2(-20, 15)
		elif direction.x > 0.1:
			dir_str = "right"
			$PunktStrzalu.position = Vector2(20, 15)
		elif direction.y < -0.1:
			dir_str = "up"
			$PunktStrzalu.position = Vector2(15, 5)
		elif direction.y > 0.1:
			dir_str = "down"
			$PunktStrzalu.position = Vector2(-15, 15)

	if state != last_state or dir_str != last_dir_str:
		set_animation(state, dir_str)
		last_state = state
		last_dir_str = dir_str

	var aktualna_predkosc = SPEED
	if Input.is_action_pressed("ui_accept"):
		aktualna_predkosc = SPEED * 1.8
	velocity = direction * aktualna_predkosc
	move_and_slide()

func _process(delta: float) -> void:
	if current_anim_frames > 1:
		anim_timer += delta
		if anim_timer >= anim_speed:
			anim_timer -= anim_speed
			current_frame_idx = (current_frame_idx + 1) % current_anim_frames
			sprite.frame = current_frame_idx

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
