extends Area2D

var speed = 700.0
var direction = Vector2.RIGHT

func _ready():
	add_to_group("pocisk")
	# Sprite pocisku kraba
	var spr = Sprite2D.new()
	var tex = load("res://assets/graphics/Scena8/pocisk_zla.png")
	if tex:
		spr.texture = tex
		spr.scale = Vector2(0.6, 0.6)
	else:
		var cr = ColorRect.new()
		cr.color = Color(0.8, 0.0, 0.8, 1.0)
		cr.size = Vector2(12, 6)
		cr.position = Vector2(-6, -3)
		add_child(cr)
	add_child(spr)

	# Kolizja
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)

	rotation = direction.angle()

	collision_mask = 5 # Warstwa 1 (gracz) i 3 (tramwaj)
	monitoring = true

	body_entered.connect(_on_body_entered)

	get_tree().create_timer(4.0).timeout.connect(func():
		if is_instance_valid(self): queue_free())

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("tramwaj"):
		queue_free()
		return
		
	if body.is_in_group("gracz"):
		var scena = get_tree().current_scene
		if scena and scena.has_method("gracz_trafiony"):
			scena.gracz_trafiony()
		queue_free()
