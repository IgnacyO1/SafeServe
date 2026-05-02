extends Area2D


@export var max_speed: float = 380.0
@export var friction: float = 300.0
@export var acceleration: float = 150.0
@export var steer_strength: float = 6.0
@export var min_steer_factor: float = 0.5

var _throttle: float = 0.0
var _velocity: float = 0.0
var _steer: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_throttle = Input.get_action_strength("ui_up")
	_steer = Input.get_axis("ui_left", "ui_right")

func _physics_process(delta: float) -> void:
	apply_throttle(delta)
	apply_rotation(delta)
	position += transform.x * _velocity * delta

func apply_throttle(delta:float) -> void:
	if _throttle > 0.0:
		_velocity += acceleration * delta
	else:
		_velocity -= friction * delta
	_velocity = clampf(_velocity, 0.0, max_speed)

func get_steer_factor() -> float:
	return clampf(
		1.0 - pow(_velocity / max_speed, 2.0),
		min_steer_factor,
		1.0
	) * steer_strength

func apply_rotation(delta: float):
	rotate(get_steer_factor()*delta*_steer)
