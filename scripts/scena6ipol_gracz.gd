extends CharacterBody2D

const SPEED = 320.0
var ostatni_kierunek_idle = "dol"
var is_shocked = false

@onready var anim_sprite = $AnimatedSprite2D

func _ready() -> void:
	z_index = 10
	_setup_sprite_frames()

func _setup_sprite_frames() -> void:
	var sf = SpriteFrames.new()
	
	# Load standard textures
	var tex_dol = load("res://assets/graphics/POLICJANTSPRITESHEET/police_dol.png")
	var tex_gora = load("res://assets/graphics/POLICJANTSPRITESHEET/police_gora.png")
	var tex_lewa = load("res://assets/graphics/POLICJANTSPRITESHEET/police_lewa.png")
	var tex_prawa = load("res://assets/graphics/POLICJANTSPRITESHEET/police_prawa.png")
	
	# Add idle animations
	sf.add_animation("policjant_idle_dol")
	sf.add_frame("policjant_idle_dol", tex_dol)
	sf.add_animation("policjant_idle_gora")
	sf.add_frame("policjant_idle_gora", tex_gora)
	sf.add_animation("policjant_idle_lewo")
	sf.add_frame("policjant_idle_lewo", tex_lewa)
	sf.add_animation("policjant_idle_prawo")
	sf.add_frame("policjant_idle_prawo", tex_prawa)
	
	# Add walk animations (using same textures for simplicity, or we can use walk sheets if needed)
	sf.add_animation("policjant_walk_dol")
	sf.add_frame("policjant_walk_dol", tex_dol)
	sf.add_animation("policjant_walk_gora")
	sf.add_frame("policjant_walk_gora", tex_gora)
	sf.add_animation("policjant_walk_lewo")
	sf.add_frame("policjant_walk_lewo", tex_lewa)
	sf.add_animation("policjant_walk_prawo")
	sf.add_frame("policjant_walk_prawo", tex_prawa)
	
	anim_sprite.sprite_frames = sf
	anim_sprite.play("policjant_idle_dol")

func _physics_process(_delta: float) -> void:
	var scena = get_parent()
	if not scena or scena.get("gra_aktywna") == false or is_shocked:
		velocity = Vector2.ZERO
		return

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
		anim_sprite.play("policjant_idle_" + ostatni_kierunek_idle)

	var spd = SPEED
	if Input.is_action_pressed("ui_accept"): 
		spd *= 1.5 # Sprint
		
	velocity = direction * spd
	move_and_slide()

	# Clamp player inside room boundaries
	global_position.x = clamp(global_position.x, 150.0, 1770.0)
	global_position.y = clamp(global_position.y, 250.0, 950.0)

func _update_animations(dir: Vector2) -> void:
	var angle = dir.angle()
	
	if abs(angle) < PI/4:
		anim_sprite.play("policjant_walk_prawo")
		ostatni_kierunek_idle = "prawo"
	elif angle >= PI/4 and angle < 3*PI/4:
		anim_sprite.play("policjant_walk_dol")
		ostatni_kierunek_idle = "dol"
	elif abs(angle) >= 3*PI/4:
		anim_sprite.play("policjant_walk_lewo")
		ostatni_kierunek_idle = "lewo"
	else:
		anim_sprite.play("policjant_walk_gora")
		ostatni_kierunek_idle = "gora"

func apply_shock(pushback_target: Vector2, duration: float) -> void:
	is_shocked = true
	velocity = Vector2.ZERO
	anim_sprite.play("policjant_idle_dol")
	
	# Tween sliding back
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", pushback_target, duration)
	await tween.finished
	
	is_shocked = false
