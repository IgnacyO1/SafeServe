extends Area2D

var speed = 600.0
var direction = Vector2.RIGHT

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area):
	if area.is_in_group("ogien"):
		area.queue_free()
		queue_free()
