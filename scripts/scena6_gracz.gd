extends CharacterBody2D

const SPEED = 300.0

@onready var anim_sprite = $AnimatedSprite2D

var ostatni_kierunek_idle = "dol"

func _ready():
	z_index = 10
	add_to_group("gracz")

func _physics_process(delta):
	var scena = get_tree().current_scene
	if scena and scena.get("gra_aktywna") != null and not scena.gra_aktywna:
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_update_animations(direction)

	var spd = SPEED
	if Input.is_action_pressed("ui_accept"):
		spd *= 1.5

	velocity = direction * spd
	move_and_slide()

	global_position.x = clamp(global_position.x, 20, 1900)
	global_position.y = clamp(global_position.y, 20, 1060)

func _update_animations(dir: Vector2):
	if dir == Vector2.ZERO:
		var idle_name = "policjant_idle_" + ostatni_kierunek_idle
		if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(idle_name):
			anim_sprite.play(idle_name)
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
