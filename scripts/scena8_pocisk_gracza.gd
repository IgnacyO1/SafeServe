extends Area2D

var speed = 1000.0
var direction = Vector2.ZERO

func _ready():
	scale = Vector2(0.07, 0.07)
	# Collision mask = 3 (warstwy 1 i 2) żeby wykrywać kraba na warstwie 2
	collision_mask = 3
	monitoring = true
	
	body_entered.connect(_on_body_entered)
	
	# Automatyczne usunięcie po 5s
	get_tree().create_timer(5.0).timeout.connect(func():
		if is_instance_valid(self): queue_free())

func _physics_process(delta):
	global_position += direction * speed * delta
	if global_position.length() > 5000:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("krab"):
		var scena = get_tree().current_scene
		if scena and scena.has_method("krab_trafiony"):
				if scena.faza_6_odpalona:
					scena.krab_trafiony(10) 
				else:
					scena.krab_trafiony(5)
		queue_free()
