extends CharacterBody2D

const SPEED = 300.0
const COOLDOWN_TIME = 0.5
var cooldown = 0.0
var knockback_velocity = Vector2.ZERO

@onready var anim_sprite = $AnimatedSprite2D
@onready var punkt_strzalu = get_node_or_null("PunktStrzalu")

# Zapamiętujemy kierunek, aby strażak stał (idle) w odpowiednią stronę po puszczeniu klawiszy
var ostatni_kierunek_idle = "dol" 

var TEX_POCISK = preload("res://assets/graphics/Scena8/pocisk_dobra.png")
var POCISK_SCRIPT = preload("res://scripts/scena8_pocisk_gracza.gd")

func _ready():
	z_index = 10
	add_to_group("gracz")
	# Tworzenie PunktStrzalu dynamicznie jeśli nie istnieje w scenie
	if not punkt_strzalu:
		punkt_strzalu = Marker2D.new()
		punkt_strzalu.name = "PunktStrzalu"
		punkt_strzalu.position = Vector2(40, 0)
		add_child(punkt_strzalu)

func _physics_process(delta):
	var scena = get_tree().current_scene
	if scena and scena.get("gra_aktywna") == false: 
		return

	# Pobieranie czystego wektora ruchu z klawiatury
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	_update_animations(direction)

	var spd = SPEED
	if scena and scena.get("faza_6_odpalona"):
		spd = 400.0 # Szybsze poruszanie się w fazie 6
		
	# Przyspieszenie (Sprint) pod klawiszem Accept (np. Spacja / Enter)
	if Input.is_action_pressed("ui_accept"): 
		spd *= 1.5

	velocity = direction * spd
	
	# Zastosowanie knockbacku
	if knockback_velocity.length() > 10.0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, delta * 3000.0)
	else:
		knockback_velocity = Vector2.ZERO
		
	move_and_slide()

	# Blokada, żeby strażak nie uciekł poza nową arenę (2560x1440)
	global_position.x = clamp(global_position.x, 40, 2520)
	global_position.y = clamp(global_position.y, 40, 1400)

	if cooldown > 0: 
		cooldown -= delta

func apply_knockback(force: Vector2):
	knockback_velocity = force


func _update_animations(dir: Vector2):
	if dir == Vector2.ZERO:
		anim_sprite.play("policjant_idle_" + ostatni_kierunek_idle)
		return

	# Matematyczne zaokrąglenie kąta do najbliższych 45 stopni (PI / 4)
	var angle = snappedf(dir.angle(), PI / 4)
	
	match angle:
		0.0: 
			anim_sprite.play("policjant_walk_prawo")
			ostatni_kierunek_idle = "prawo"
		PI / 4.0: 
			anim_sprite.play("policjant_skos_dol_prawo")
			ostatni_kierunek_idle = "prawo"
		PI / 2.0: 
			anim_sprite.play("policjant_walk_dol")
			ostatni_kierunek_idle = "dol"
		3.0 * PI / 4.0: 
			anim_sprite.play("policjant_skos_dol_lewo")
			ostatni_kierunek_idle = "lewo"
		PI, -PI: 
			anim_sprite.play("policjant_walk_lewo")
			ostatni_kierunek_idle = "lewo"
		-3.0 * PI / 4.0: 
			anim_sprite.play("policjant_skos_gora_lewo")
			ostatni_kierunek_idle = "lewo"
		-PI / 2.0: 
			anim_sprite.play("policjant_walk_gora")
			ostatni_kierunek_idle = "gora"
		-PI / 4.0: 
			anim_sprite.play("policjant_skos_gora_prawo")
			ostatni_kierunek_idle = "prawo"

func _unhandled_input(event):
	var scena = get_tree().current_scene
	if scena and scena.get("gra_aktywna") == false: 
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if cooldown <= 0:
				_shoot()
				cooldown = COOLDOWN_TIME

func _shoot():
	# Dynamiczne budowanie węzła pocisku
	var pocisk = Area2D.new()
	pocisk.collision_mask = 3  # Warstwy 1+2 żeby trafić kraba na warstwie 2
	pocisk.monitoring = true
	pocisk.set_script(POCISK_SCRIPT)
	
	# Dodawanie Sprite'a w locie
	var spr = Sprite2D.new()
	spr.texture = TEX_POCISK
	pocisk.add_child(spr)
	
	# Dodawanie kolizji w locie
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0 # Rozmiar kolizji pocisku gracza
	col.shape = shape
	pocisk.add_child(col)
	
	var mouse_pos = get_global_mouse_position()
	var shoot_origin = punkt_strzalu.global_position if punkt_strzalu else global_position
	pocisk.direction = (mouse_pos - shoot_origin).normalized()
	pocisk.rotation = pocisk.direction.angle()
	pocisk.global_position = shoot_origin
	
	# Zwiększ prędkość pocisku w fazie 6
	var scena = get_tree().current_scene
	if scena and scena.get("faza_6_odpalona"):
		pocisk.speed = 1000.0 # Szybsze pociski w fazie 6
	
	get_parent().add_child(pocisk)
