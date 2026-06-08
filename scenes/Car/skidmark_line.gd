extends Line2D

@export var fade_time: float = 3.0
var time_elapsed: float = 0.0
var active: bool = true

func _process(delta: float) -> void:
	if not active:
		time_elapsed += delta
		var alpha = clamp(0.5 - (time_elapsed / fade_time) * 0.5, 0.0, 0.5)
		modulate.a = alpha
		if alpha <= 0.0:
			queue_free()
