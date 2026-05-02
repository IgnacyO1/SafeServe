extends Area2D

@export var max_speed: float = 500.0
@export var acceleration: float = 200.0
@export var brake_force: float = 400.0
@export var friction: float = 50.0

@export var steer_speed: float = 5.0
@export var steer_limit: float = 0.6

@export var traction_fast: float = 0.2
@export var traction_slow: float = 0.5

var velocity: Vector2 = Vector2.ZERO
var steer_angle: float = 0.0

var _throttle: float = 0.0
var _steer_input: float = 0.0

func _process(delta: float) -> void:
	_throttle = Input.get_axis("ui_down", "ui_up") # przód/tył
	_steer_input = Input.get_axis("ui_left", "ui_right")

func _physics_process(delta: float) -> void:
	apply_engine(delta)
	apply_friction(delta)
	apply_steering(delta)
	apply_lateral_friction()

	position += velocity * delta
	
func apply_engine(delta: float) -> void:
	var forward = transform.x
	# Sprawdzamy obecną prędkość wzdłuż osi przód-tył samochodu
	var forward_speed = velocity.dot(forward)
	
	if _throttle != 0:
		# is_braking jest prawdą, jeśli wciskasz gaz w przeciwną stronę niż jedziesz
		# (abs > 10.0 zapobiega "szarpaniu" przy zera i pozwala płynnie przejść w cofanie)
		var is_braking = sign(_throttle) != sign(forward_speed) and abs(forward_speed) > 10.0
		
		if is_braking:
			# Zbijamy prędkość do zera używając silnego brake_force
			velocity = velocity.move_toward(Vector2.ZERO, brake_force * delta)
		else:
			# Zwykłe przyspieszanie (w przód lub w tył)
			if _throttle > 0:
				velocity += forward * acceleration * _throttle * delta
			elif _throttle < 0:
				velocity += forward * acceleration * _throttle * 0.6 * delta # słabsze cofanie


func apply_friction(delta: float) -> void:
	if _throttle == 0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# ograniczenie max prędkości
	velocity = velocity.limit_length(max_speed)
func apply_steering(delta: float) -> void:
	var speed = velocity.length()
	
	# brak skrętu gdy prawie stoisz
	if speed < 5:
		return

	# płynny skręt (nie instant)
	steer_angle = lerp(steer_angle, _steer_input * steer_limit, steer_speed * delta)

	# kierunek ruchu (ważne!)
	var direction = velocity.normalized()
	
	# cofanie odwraca skręt
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
