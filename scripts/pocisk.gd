extends Area2D

var speed = 600.0
var direction = Vector2.RIGHT

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	var move_vec = direction * speed * delta
	
	# Raycast sprawdzający ściany wzdłuż ruchu pocisku, aby nie przelatywał przez cienkie polygony!
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + move_vec)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1  # Tylko ściany (layer 1), ignoruj NPC (layer 2)
	var result = space_state.intersect_ray(query)
	
	if result:
		queue_free()
		return
		
	position += move_vec

func _on_area_entered(area):
	if area.is_in_group("ogien"):
		var scena_głowna = get_tree().current_scene
		if scena_głowna.has_method("zgaszono_ogien"):
			scena_głowna.zgaszono_ogien(area)
		elif area.get_parent().has_method("zgaszono_ogien"):
			area.get_parent().zgaszono_ogien(area)

		area.queue_free()
		queue_free()
