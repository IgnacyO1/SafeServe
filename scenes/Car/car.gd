extends CharacterBody2D

@export var max_speed: float = 600.0
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

	move_and_slide()
	# Wywołujemy aktualizację dźwięku silnika
	update_engine_sound(delta)
	if Input.is_action_just_pressed("horn"): 
		play_horn_sound() 
		make_way_for_emergency()
	
	
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

func make_way_for_emergency():
	# Szukamy managera w tej samej gałęzi co MapManager lub bezpośrednio w scenie
	var traffic_manager = get_tree().current_scene.find_child("Traffic Manager", true, false)
	
	if traffic_manager == null:
		print("BŁĄD: Nie znaleziono TrafficManagera w scenie!")
		return

	for npc in traffic_manager.active_agents:
		if is_instance_valid(npc):
			var dist = global_position.distance_to(npc.global_position)
			# 1000 pikseli = 50m przy skali 20
			if dist < 5000.0:
				if npc.has_method("yield_to_emergency"):
					npc.yield_to_emergency()

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
	var target_pitch = lerp(0.4, 1.3, speed_ratio)
	
	# 4. Płynnie zmieniamy pitch, żeby dźwięk nie skakał gwałtownie
	engine_player.pitch_scale = lerp(engine_player.pitch_scale, target_pitch, 10.0 * delta)
	
	# OPTYMALNIE: Możesz też lekko zgłośnić silnik, gdy jedzie szybko
	var target_volume = lerp(-15.0, -10.0, speed_ratio) # wartości w dB
	engine_player.volume_db = lerp(engine_player.volume_db, target_volume, 5.0 * delta)
