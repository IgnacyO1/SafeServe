extends CharacterBody2D

const SPEED = 300.0
const COOLDOWN_TIME = 0.5

var cooldown = 0.0
var POCISK_SCRIPT = preload("res://scripts/pocisk_gracza_s8.gd")

func _ready():
	z_index = 10
	add_to_group("gracz")

func _physics_process(delta):
	var scena = get_tree().current_scene
	if scena and not scena.get("gra_aktywna"):
		return

	# Ruch
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left"): direction.x -= 1
	if Input.is_action_pressed("ui_down"): direction.y += 1
	if Input.is_action_pressed("ui_up"): direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_update_sprite(direction)

	var spd = SPEED
	if Input.is_action_pressed("ui_accept"):
		spd = SPEED * 1.5
	velocity = direction * spd
	move_and_slide()

	# Ograniczenie do areny (1920x1080)
	global_position.x = clamp(global_position.x, 40, 1880)
	global_position.y = clamp(global_position.y, 40, 1040)

	# Cooldown strzelania
	if cooldown > 0:
		cooldown -= delta

func _update_sprite(dir):
	var sprite = get_node_or_null("Sprite2D")
	var sprite_skosy = get_node_or_null("SpriteSkosy")
	var jest_skos = dir.x != 0 and dir.y != 0

	if jest_skos and sprite_skosy:
		if sprite: sprite.visible = false
		sprite_skosy.visible = true
		if dir.x < 0 and dir.y < 0:
			sprite_skosy.frame = 0
		elif dir.x > 0 and dir.y < 0:
			sprite_skosy.frame = 1
		elif dir.x < 0 and dir.y > 0:
			sprite_skosy.frame = 3
		elif dir.x > 0 and dir.y > 0:
			sprite_skosy.frame = 2
	else:
		if sprite: sprite.visible = true
		if sprite_skosy: sprite_skosy.visible = false
		if not sprite: return
		if abs(dir.x) > abs(dir.y):
			sprite.frame = 1 if dir.x > 0 else 2
		else:
			sprite.frame = 0 if dir.y < 0 else 3

func _unhandled_input(event):
	var scena = get_tree().current_scene
	if scena and not scena.get("gra_aktywna"):
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if cooldown <= 0:
				_shoot()
				cooldown = COOLDOWN_TIME

func _shoot():
	var marker = get_node_or_null("PunktStrzalu")
	if not marker:
		return
	var pocisk = Area2D.new()
	pocisk.set_script(POCISK_SCRIPT)
	var mouse_pos = get_global_mouse_position()
	pocisk.direction = (mouse_pos - marker.global_position).normalized()
	pocisk.global_position = marker.global_position
	get_parent().add_child(pocisk)
