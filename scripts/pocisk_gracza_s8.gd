extends Area2D

var speed = 700.0
var direction = Vector2.RIGHT

func _ready():
	# Sprite pocisku
	var spr = Sprite2D.new()
	var tex = load("res://assets/graphics/Scena8/pocisk_dobra.png")
	if tex:
		spr.texture = tex
		spr.scale = Vector2(0.6, 0.6)
	else:
		# Fallback: kolorowy prostokąt
		var cr = ColorRect.new()
		cr.color = Color(0.0, 1.0, 1.0, 1.0)
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

	# Obrót w kierunku lotu
	rotation = direction.angle()

	# Sygnały
	body_entered.connect(_on_body_entered)

	# Auto-zniszczenie po 3s
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(self): queue_free())

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("krab"):
		var scena = get_tree().current_scene
		if scena and scena.has_method("krab_trafiony"):
			scena.krab_trafiony(10)
		queue_free()
