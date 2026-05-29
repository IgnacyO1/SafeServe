extends CharacterBody2D

var predkosc_bazowa = 120.0
var predkosc = 120.0
var kierunek = Vector2(-1, 0.5).normalized()
var czas_gry = 0.0
var strzal_timer = 0.0
var strzal_interwal = 1.0  

var teleportacja_aktywna = false
var teleport_timer = 0.0
var teleport_interwal = 5.0  
var aktualna_faza = 1

# Referencja do gracza – boss sam go znajdzie w grupie!
var gracz_ref = null 

var TEX_POCISK_ZLA = preload("res://assets/graphics/Scena8/pocisk_zla.png")
var POCISK_ZLA_SCRIPT = preload("res://scripts/scena8_pocisk_kraba.gd")

# Granice poruszania się kraba na arenie 2560x1440
const ARENA_MIN = Vector2(100, 100)
const ARENA_MAX = Vector2(2460, 1340)

@onready var sprite = $Sprite2D

func _ready():
	z_index = 8
	add_to_group("krab")
	
	# Upewnij się, że CollisionShape2D ma przypisany kształt
	var col = get_node_or_null("CollisionShape2D")
	if col and not col.shape:
		var shape = RectangleShape2D.new()
		shape.size = Vector2(160, 100)
		col.shape = shape
	elif not col:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape = RectangleShape2D.new()
		shape.size = Vector2(160, 100)
		col.shape = shape
		add_child(col)
	
	# Losowy kierunek startowy
	kierunek = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Szukamy gracza w grupie "gracz" po załadowaniu sceny
	call_deferred("_znajdz_gracza")

func _znajdz_gracza():
	var gracze = get_tree().get_nodes_in_group("gracz")
	if gracze.size() > 0:
		gracz_ref = gracze[0]

func _physics_process(delta):
	var scena = get_tree().current_scene
	if scena and scena.get("gra_aktywna") == false: 
		return
		
	czas_gry += delta
	# Krab przyspiesza o 2 piksele na sekundę
	predkosc = predkosc_bazowa + czas_gry * 2.0  
	velocity = kierunek * predkosc
	move_and_slide()

	# Odbijanie od ścian lewa/prawa
	if global_position.x <= ARENA_MIN.x or global_position.x >= ARENA_MAX.x:
		kierunek.x = -kierunek.x
		global_position.x = clamp(global_position.x, ARENA_MIN.x + 5, ARENA_MAX.x - 5)
		
	# Odbijanie od ścian góra/dół
	if global_position.y <= ARENA_MIN.y or global_position.y >= ARENA_MAX.y:
		kierunek.y = -kierunek.y
		global_position.y = clamp(global_position.y, ARENA_MIN.y + 5, ARENA_MAX.y - 5)

	# Losowa zmiana kierunku lotu raz na jakiś czas (nieprzewidywalność bossa)
	if randi() % 180 == 0:  
		kierunek = kierunek.rotated(randf_range(-0.8, 0.8)).normalized()

	# Licznik strzelania
	strzal_timer += delta
	if strzal_timer >= strzal_interwal:
		strzal_timer = 0.0
		_strzal()

	# Licznik teleportacji
	if teleportacja_aktywna:
		teleport_timer += delta
		if teleport_timer >= teleport_interwal:
			teleport_timer = 0.0
			_teleportuj()

func _strzal():
	if not gracz_ref or not is_instance_valid(gracz_ref): 
		return
		
	var do_gracza = gracz_ref.global_position - global_position
	var kat_bazowy = do_gracza.angle()
	var odchylenie = randf_range(-0.175, 0.175)
	var kat_finalny = kat_bazowy + odchylenie
	var dir = Vector2(cos(kat_finalny), sin(kat_finalny))
	
	# Budowanie pocisku - skrypt pocisk_kraba sam tworzy sobie sprite i kolizję w _ready()
	var pocisk = Area2D.new()
	pocisk.set_script(POCISK_ZLA_SCRIPT)
	pocisk.direction = dir
	pocisk.global_position = global_position
	get_parent().add_child(pocisk)

func _teleportuj():
	if sprite:
		var tw = create_tween()
		# Mignięcie na czerwono przed teleportacją
		tw.tween_property(sprite, "modulate", Color(1, 0, 0, 0.3), 0.15)
		tw.tween_callback(func():
			global_position = Vector2(
				randf_range(ARENA_MIN.x + 100, ARENA_MAX.x - 100),
				randf_range(ARENA_MIN.y + 100, ARENA_MAX.y - 100)
			)
			kierunek = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func ustaw_faze(faza: int):
	aktualna_faza = faza
	match faza:
		1:
			predkosc_bazowa = 120.0
			strzal_interwal = 1.0
			teleportacja_aktywna = false
		2:  
			predkosc_bazowa = 160.0
			strzal_interwal = 0.9
			teleportacja_aktywna = true
			teleport_interwal = 5.0
		3:  
			predkosc_bazowa = 210.0
			strzal_interwal = 0.8
			teleportacja_aktywna = true
			teleport_interwal = 3.0
		4:  
			predkosc_bazowa = 280.0
			strzal_interwal = 0.6
			teleportacja_aktywna = true
			teleport_interwal = 2.0
