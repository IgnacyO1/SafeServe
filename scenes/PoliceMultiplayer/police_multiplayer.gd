extends CharacterBody2D

@export var max_speed: float = 700.0
@export var acceleration: float = 200.0
@export var brake_force: float = 400.0
@export var friction: float = 50.0
@export var steer_speed: float = 5.0
@export var steer_limit: float = 0.6
@export var traction_fast: float = 0.2
@export var traction_slow: float = 0.5

@onready var horn_player: AudioStreamPlayer2D = $HornPlayer
@onready var lights: AnimatedSprite2D = $EmergencyLights
@onready var siren_player: AudioStreamPlayer2D = $SirenPlayer

var lights_active: bool = false
var steer_angle: float = 0.0
var _throttle: float = 0.0
var _steer_input: float = 0.0
var map_manager: Node2D = null
var is_on_grass: bool = false

func _ready():
	add_to_group("police") # Każdy zreplikowany wóz ląduje w grupie pościgu
	
	# Wyłączenie kolizji na start (ochrona przed zablokowaniem w teksturach)
	var original_mask = collision_mask
	collision_mask = 0
	get_tree().create_timer(1.0).timeout.connect(func():
		collision_mask = original_mask
		velocity = Vector2.ZERO 
	)
	
	map_manager = get_tree().current_scene.find_child("MapManager", true, false)

func _process(delta: float) -> void:
	# KLUCZOWE ZABEZPIECZENIE: Czytamy klawiaturę tylko u gracza, który kontroluje ten wóz!
	if not is_multiplayer_authority(): return
	
	_throttle = Input.get_axis("ui_down", "ui_up") 
	_steer_input = Input.get_axis("ui_left", "ui_right")
	
	if Input.is_action_just_pressed("toggle_lights"):
		# Wysyłamy sygnał RPC do serwera, żeby zsynchronizował koguty u wszystkich
		rpc("sync_emergency_lights", !lights_active)

	if Input.is_action_just_pressed("horn"):
		play_horn_sound()

func _physics_process(delta: float) -> void:
	# Tylko właściciel pojazdu liczy fizykę jazdy
	if not is_multiplayer_authority(): return

	if map_manager and map_manager.has_method("is_point_on_road"):
		is_on_grass = not map_manager.is_point_on_road(global_position)
	else:
		is_on_grass = false

	apply_engine(delta)
	apply_friction(delta)
	apply_steering(delta)
	apply_lateral_friction()

	move_and_slide()

# RPC: Każdy gracz wysyła informację o zmianie świateł, serwer przekazuje ją wszystkim klientom
@rpc("any_peer", "call_local", "reliable")
func sync_emergency_lights(mode: bool):
	lights_active = mode
	if lights:
		lights.visible = mode
		if mode: lights.play()
		else: lights.stop()
	
	
func apply_engine(delta: float) -> void:
	var forward = transform.x
	var forward_speed = velocity.dot(forward)
	
	# Słabsze przyspieszenie na trawie
	var current_acceleration = acceleration
	if is_on_grass:
		current_acceleration *= 0.5
	
	if _throttle != 0:
		var is_braking = sign(_throttle) != sign(forward_speed) and abs(forward_speed) > 10.0
		
		if is_braking:
			velocity = velocity.move_toward(Vector2.ZERO, brake_force * delta)
		else:
			if _throttle > 0:
				velocity += forward * current_acceleration * _throttle * delta
			elif _throttle < 0:
				velocity += forward * current_acceleration * _throttle * 0.6 * delta


func apply_friction(delta: float) -> void:
	if _throttle == 0:
		# Trawa stawia opór i szybciej zatrzymuje auto (tarcie x3)
		var current_friction = friction * (3.0 if is_on_grass else 1.0)
		velocity = velocity.move_toward(Vector2.ZERO, current_friction * delta)

	# 2x niższa prędkość maksymalna na trawie
	var current_max_speed = max_speed
	if is_on_grass:
		current_max_speed = max_speed * 0.6

	velocity = velocity.limit_length(current_max_speed)

func apply_steering(delta: float) -> void:
	var speed = velocity.length()
	if speed < 5:
		return

	steer_angle = lerp(steer_angle, _steer_input * steer_limit, steer_speed * delta)
	var direction = velocity.normalized()
	var forward = transform.x
	var dot = direction.dot(forward)
	var steer_dir = 1.0 if dot > 0 else -1.0

	rotation += steer_angle * steer_dir * delta * speed / 100.0

func apply_lateral_friction() -> void:
	var forward = transform.x
	var right = transform.y

	var forward_vel = forward * velocity.dot(forward)
	var lateral_vel = right * velocity.dot(right)

	var speed = velocity.length()
	var traction = traction_fast if speed > 200 else traction_slow

	velocity = forward_vel + lateral_vel * clamp(1.0 - traction, 0.0, 0.3)

func play_horn_sound():
	if horn_player:
		if not horn_player.playing:
			horn_player.play()


func turn_emergency_lights( mode : bool ):
	print("Przycisk świateł naciśnięty!")
	lights_active = !lights_active
	lights.visible = mode
	if mode:
		lights.play()
	else:
		lights.stop()
func turn_siren( mode : bool ):
	if mode:
		siren_player.play() # Uruchamia dźwięk
	else:
		siren_player.stop() # Zatrzymuje dźwięk
