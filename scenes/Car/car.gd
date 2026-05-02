extends Area2D

var _throttle: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_throttle = Input.get_action_strength("ui_up")


func _physics_process(delta: float) -> void:
	position += transform.x * 100.0 * _throttle * delta
