extends Area2D

var speed = 1000.0 # Szybsze niż podstawowe
var direction = Vector2.RIGHT

func _ready():
	# Sprite pocisku fali
	var spr = Sprite2D.new()
	var tex = load("res://assets/graphics/Scena8/pocisk_zla.png")
	if tex:
		spr.texture = tex
		spr.scale = Vector2(0.8, 0.8) # Troche wiekszy
		spr.modulate = Color(0.5, 0.0, 1.0) # Lekko zmieniony kolor zeby sie odroznial (fioletowawy)
	else:
		var cr = ColorRect.new()
		cr.color = Color(0.5, 0.0, 1.0, 1.0)
		cr.size = Vector2(16, 8)
		cr.position = Vector2(-8, -4)
		add_child(cr)
	add_child(spr)

	# Kolizja
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

	rotation = randf_range(0.0, TAU)

	body_entered.connect(_on_body_entered)

	get_tree().create_timer(4.0).timeout.connect(func():
		if is_instance_valid(self): queue_free())

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("gracz"):
		var scena = get_tree().current_scene
		if scena and scena.has_method("gracz_trafiony"):
			scena.gracz_trafiony()
		queue_free()
