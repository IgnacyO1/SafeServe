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
		# Powiadamiamy scene 4 że zgasiliśmy ten ogień
		var scena_głowna = get_tree().current_scene
		if scena_głowna.has_method("zgaszono_ogien"):
			scena_głowna.zgaszono_ogien(area)
		elif area.get_parent().has_method("zgaszono_ogien"):
			area.get_parent().zgaszono_ogien(area)

		area.queue_free()
		queue_free()
