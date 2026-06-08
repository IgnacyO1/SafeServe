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
@onready var engine_player: AudioStreamPlayer2D = $EnginePlayer
@onready var lights: AnimatedSprite2D = $EmergencyLights
@onready var siren_player: AudioStreamPlayer2D = $SirenPlayer
var lights_active: bool = false
# ZMIENNA velocity została usunięta - CharacterBody2D ma ją wbudowaną!

var steer_angle: float = 0.0
var _throttle: float = 0.0
var _steer_input: float = 0.0
var map_manager: Node2D = null
var is_on_grass: bool = false
var _steer_duration: float = 0.0

@onready var rear_left_wheel: Marker2D = $RearLeftWheel
@onready var rear_right_wheel: Marker2D = $RearRightWheel
var skidmark_scene = preload("res://scenes/Car/skidmark_line.tscn")
var current_left_skid: Line2D = null
var current_right_skid: Line2D = null
var is_drifting: bool = false

# Dodaj to na końcu car.gd
func _ready():
	# Zapamiętujemy oryginalną maskę (co auto widzi)
	var original_mask = collision_mask
	# Wyłączamy maskę (auto przenika przez wszystko)
	collision_mask = 0
	
	# Po 1 sekundzie przywracamy kolizje
	get_tree().create_timer(1.0).timeout.connect(func():
		collision_mask = original_mask
		# Opcjonalnie zerujemy prędkość, by zapobiec nagłemu skokowi
		velocity = Vector2.ZERO 
	)
	
	# Szukamy managera w scenie
	map_manager = get_tree().current_scene.find_child("MapManager", true, false)

func _process(delta: float) -> void:
	_throttle = Input.get_axis("ui_down", "ui_up") # przód/tył
	_steer_input = Input.get_axis("ui_left", "ui_right")
	# Obsługa włączania/wyłączania świateł
	if Input.is_action_just_pressed("toggle_lights"):
		lights_active = !lights_active
		turn_emergency_lights(lights_active)

func _physics_process(delta: float) -> void:
	if map_manager and map_manager.has_method("is_point_on_road"):
		is_on_grass = not map_manager.is_point_on_road(global_position)
	else:
		is_on_grass = false

	apply_engine(delta)
	apply_friction(delta)
	apply_steering(delta)
	apply_lateral_friction()
	_update_skidmarks()

	# USUNIĘTO: position += velocity * delta 
	# CharacterBody2D sam przelicza pozycję na podstawie zmiennej velocity podczas move_and_slide()
	move_and_slide()
	# Wewnątrz _physics_process lub _input w car.gd
	update_engine_sound(delta)
	if Input.is_action_just_pressed("horn"): # Musisz dodać "horn" w Input Map
		play_horn_sound() # Opcjonalnie
	
	
func apply_engine(delta: float) -> void:
	var forward = transform.x
	var forward_speed = velocity.dot(forward)
	
	# Słabsze przyspieszenie na trawie
	var current_acceleration = acceleration
	if is_on_grass:
		current_acceleration *= 0.5
	
	# Hamulec ręczny (Spacja) - mniejsza utrata prędkości
	if Input.is_key_pressed(KEY_SPACE):
		velocity = velocity.move_toward(Vector2.ZERO, brake_force * 0.4 * delta)
		return

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

	# 1. Dynamiczne zmniejszanie limitu skrętu przy wyższych prędkościach
	var speed_ratio = clamp(speed / max_speed, 0.0, 1.0)
	var current_steer_limit = steer_limit * lerp(1.0, 0.45, speed_ratio)

	# 2. Płynna zmiana kąta skrętu (szybsze prostowanie kół)
	var current_steer_speed = steer_speed
	if _steer_input == 0:
		current_steer_speed = 8.0 # Szybszy powrót kół do jazdy na wprost
	steer_angle = lerp(steer_angle, _steer_input * current_steer_limit, current_steer_speed * delta)
	
	# 3. Zliczanie czasu trzymania przycisku skrętu dla progresywnego skręcania
	if _steer_input != 0:
		_steer_duration += delta
	else:
		_steer_duration = 0.0
	var steer_boost = lerp(1.0, 1.8, clamp(_steer_duration / 0.8, 0.0, 1.0))

	var direction = velocity.normalized()
	var forward = transform.x
	var dot = direction.dot(forward)
	var steer_dir = 1.0 if dot > 0 else -1.0

	# 4. Złagodzony, zoptymalizowany pod kątem responsywności mnożnik prędkości (clamp)
	var speed_factor = clamp(speed / 90.0, 0.3, 4.0)
	rotation += steer_angle * steer_boost * steer_dir * delta * speed_factor

func apply_lateral_friction() -> void:
	var forward = transform.x
	var right = transform.y

	var forward_vel = forward * velocity.dot(forward)
	var lateral_vel = right * velocity.dot(right)

	var speed = velocity.length()
	var lateral_speed = lateral_vel.length()

	# Warunek poślizgu: zaciągnięty ręczny (Spacja) LUB duża siła odśrodkowa boczna
	var is_handbrake = Input.is_key_pressed(KEY_SPACE)
	is_drifting = is_handbrake or (lateral_speed > 160.0 and speed > 150.0)

	var lateral_retention = 0.3
	if is_drifting:
		lateral_retention = 0.96 if is_handbrake else 0.90

	velocity = forward_vel + lateral_vel * lateral_retention

func play_horn_sound():
	if horn_player:
		if not horn_player.playing:
			horn_player.play()



func turn_emergency_lights( mode : bool ):
	print("Przycisk świateł naciśnięty!")
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

func update_engine_sound(delta: float) -> void:
	if not engine_player:
		return
		
	# 1. Obliczamy aktualną prędkość auta
	var speed = velocity.length()
	
	# 2. Wyznaczamy procent prędkości względem maksymalnej (wartość od 0.0 do 1.0)
	var speed_ratio = speed / max_speed
	
	# 3. Ustalamy zakres pitch (wysokości tonu)
	# Na postoju pitch = 0.8 (niski bas), przy max prędkości pitch = 2.2 (wysokie obroty)
	var target_pitch = lerp(0.7, 2.0, speed_ratio)
	
	# 4. Płynnie zmieniamy pitch, żeby dźwięk nie skakał gwałtownie
	engine_player.pitch_scale = lerp(engine_player.pitch_scale, target_pitch, 10.0 * delta)
	
	# OPTYMALNIE: Możesz też lekko zgłośnić silnik, gdy jedzie szybko
	var target_volume = lerp(-19.0, -12.0, speed_ratio) # wartości w dB
	engine_player.volume_db = lerp(engine_player.volume_db, target_volume, 5.0 * delta)

func _update_skidmarks() -> void:
	var speed = velocity.length()
	if is_drifting and speed > 60.0 and rear_left_wheel and rear_right_wheel:
		if not current_left_skid:
			current_left_skid = _start_skidmark(rear_left_wheel.global_position)
		else:
			_add_skidmark_point(current_left_skid, rear_left_wheel.global_position)

		if not current_right_skid:
			current_right_skid = _start_skidmark(rear_right_wheel.global_position)
		else:
			_add_skidmark_point(current_right_skid, rear_right_wheel.global_position)
	else:
		if current_left_skid:
			current_left_skid.active = false
			current_left_skid = null
		if current_right_skid:
			current_right_skid.active = false
			current_right_skid = null

func _start_skidmark(pos: Vector2) -> Line2D:
	var skid = skidmark_scene.instantiate()
	get_parent().add_child(skid)
	skid.global_position = Vector2.ZERO
	skid.add_point(pos)
	return skid

func _add_skidmark_point(skid: Line2D, pos: Vector2) -> void:
	if skid.get_point_count() > 0:
		var last_pos = skid.get_point_position(skid.get_point_count() - 1)
		if last_pos.distance_to(pos) < 6.0:
			return
	skid.add_point(pos)
