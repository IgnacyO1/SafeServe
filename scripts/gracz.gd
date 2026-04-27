extends CharacterBody2D

const SPEED = 250.0
const POCISK = preload("res://scenes/pocisk.tscn")

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	velocity = direction * SPEED
	move_and_slide()

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var pocisk = POCISK.instantiate()
			get_parent().add_child(pocisk)
			pocisk.global_position = $PunktStrzalu.global_position
			pocisk.direction = (get_global_mouse_position() - global_position).normalized()
	
	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed:
			if przy_npc != null:
				print("Zakładasz maskę na: ", przy_npc.name)
				przy_npc.queue_free()
				przy_npc = null


var przy_npc = null



func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("npc"):
		przy_npc = null
		
		
func _on_area_entered(area: Area2D) -> void:
	print("Weszła strefa: ", area.name)
	if area.is_in_group("npc"):
		przy_npc = area
		print("Babcia w zasięgu!")
