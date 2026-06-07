extends CharacterBody2D

const SPEED = 320.0
var ostatni_kierunek_idle = "dol"
var is_shocked = false

@onready var anim_sprite = $AnimatedSprite2D

func _ready() -> void:
	z_index = 10
	# Funkcja _setup_sprite_frames() została usunięta, 
	# ponieważ teraz używamy skopiowanego, gotowego AnimatedSprite2D z edytora.
	if anim_sprite and anim_sprite.sprite_frames.has_animation("policjant_idle_dol"):
		anim_sprite.play("policjant_idle_dol")

func _physics_process(_delta: float) -> void:
	var scena = get_parent()
	if not scena or scena.get("gra_aktywna") == false or is_shocked:
		velocity = Vector2.ZERO
		# Jeśli gracz stoi z powodu braku aktywności sceny lub szoku, odpala się idle
		if anim_sprite:
			anim_sprite.play("policjant_idle_" + ostatni_kierunek_idle)
		return

	# Obsługa poruszania identyczna jak w oryginalnym skrypcie 6 i pół (WSAD / Strzałki)
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_update_animations(direction)
	else:
		var idle_name = "policjant_idle_" + ostatni_kierunek_idle
		if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(idle_name):
			anim_sprite.play(idle_name)

	var spd = SPEED
	if Input.is_action_pressed("ui_accept"): 
		spd *= 1.5 # Sprint
		
	velocity = direction * spd
	move_and_slide()

	# Pozycjonowanie wewnątrz pokoju (granice ze sceny 6.5)
	global_position.x = clamp(global_position.x, 150.0, 1770.0)
	global_position.y = clamp(global_position.y, 250.0, 950.0)

# NOWY SYSTEM ANIMACJI - Dokładnie taki sam match (kąty i skosy) jak w scenie 6
func _update_animations(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return

	if not anim_sprite:
		return

	var angle = snappedf(dir.angle(), PI / 4)
	match angle:
		0.0:
			anim_sprite.play("policjant_walk_prawo")
			ostatni_kierunek_idle = "prawo"
		PI / 4.0:
			anim_sprite.play("policjant_skos_dol_prawo")
			ostatni_kierunek_idle = "prawo"
		PI / 2.0:
			anim_sprite.play("policjant_walk_dol")
			ostatni_kierunek_idle = "dol"
		3.0 * PI / 4.0:
			anim_sprite.play("policjant_skos_dol_lewo")
			ostatni_kierunek_idle = "lewo"
		PI, -PI:
			anim_sprite.play("policjant_walk_lewo")
			ostatni_kierunek_idle = "lewo"
		-3.0 * PI / 4.0:
			anim_sprite.play("policjant_skos_gora_lewo")
			ostatni_kierunek_idle = "lewo"
		-PI / 2.0:
			anim_sprite.play("policjant_walk_gora")
			ostatni_kierunek_idle = "gora"
		-PI / 4.0:
			anim_sprite.play("policjant_skos_gora_prawo")
			ostatni_kierunek_idle = "prawo"

func apply_shock(pushback_target: Vector2, duration: float) -> void:
	is_shocked = true
	velocity = Vector2.ZERO
	if anim_sprite:
		anim_sprite.play("policjant_idle_dol")
	
	# Tween sliding back
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", pushback_target, duration)
	await tween.finished
	
	is_shocked = false
