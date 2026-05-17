extends CharacterBody2D

# Parametry
var predkosc_bazowa = 120.0
var predkosc = 120.0
var kierunek = Vector2(1, 0.5).normalized()
var czas_gry = 0.0

# Strzelanie
var strzal_timer = 0.0
var strzal_interwal = 1.0  # co ile sekund strzela
var POCISK_SCRIPT = preload("res://scripts/pocisk_kraba.gd")

# Teleportacja
var teleportacja_aktywna = false
var teleport_timer = 0.0
var teleport_interwal = 5.0  # co ile sekund teleport

# Faza
var aktualna_faza = 1

# Referencja do gracza (ustawiana przez scenę)
var gracz_ref = null

# Granice areny
const ARENA_MIN = Vector2(80, 80)
const ARENA_MAX = Vector2(1840, 1000)

func _ready():
	z_index = 8
	add_to_group("krab")
	# Losowy kierunek startowy
	kierunek = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _physics_process(delta):
	var scena = get_tree().current_scene
	if scena and not scena.get("gra_aktywna"):
		return

	czas_gry += delta

	# Ruch: patrol po arenie, odbijanie od krawędzi
	# Prędkość rośnie powoli z czasem (niezależnie od fazy)
	predkosc = predkosc_bazowa + czas_gry * 2.0  # +2 px/s co sekundę

	velocity = kierunek * predkosc
	move_and_slide()

	# Odbijanie od granic areny
	if global_position.x <= ARENA_MIN.x or global_position.x >= ARENA_MAX.x:
		kierunek.x = -kierunek.x
		global_position.x = clamp(global_position.x, ARENA_MIN.x + 5, ARENA_MAX.x - 5)
	if global_position.y <= ARENA_MIN.y or global_position.y >= ARENA_MAX.y:
		kierunek.y = -kierunek.y
		global_position.y = clamp(global_position.y, ARENA_MIN.y + 5, ARENA_MAX.y - 5)

	# Losowa zmiana kierunku co jakiś czas (żeby nie był przewidywalny)
	if randi() % 180 == 0:  # ~raz na 3 sekundy przy 60fps
		kierunek = kierunek.rotated(randf_range(-0.8, 0.8)).normalized()

	# Strzelanie
	strzal_timer += delta
	if strzal_timer >= strzal_interwal:
		strzal_timer = 0.0
		_strzal()

	# Teleportacja
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

	# Losowe odchylenie ±10 stopni (w radianach: ±0.175)
	var odchylenie = randf_range(-0.175, 0.175)
	var kat_finalny = kat_bazowy + odchylenie

	var dir = Vector2(cos(kat_finalny), sin(kat_finalny))

	var pocisk = Area2D.new()
	pocisk.set_script(POCISK_SCRIPT)
	pocisk.direction = dir
	pocisk.global_position = global_position
	get_parent().add_child(pocisk)

func _teleportuj():
	# Efekt wizualny: flash przed teleportem
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1, 0, 0, 0.3), 0.15)
		tw.tween_callback(func():
			# Nowa losowa pozycja
			global_position = Vector2(
				randf_range(ARENA_MIN.x + 100, ARENA_MAX.x - 100),
				randf_range(ARENA_MIN.y + 100, ARENA_MAX.y - 100)
			)
			# Nowy losowy kierunek ruchu
			kierunek = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	else:
		global_position = Vector2(
			randf_range(ARENA_MIN.x + 100, ARENA_MAX.x - 100),
			randf_range(ARENA_MIN.y + 100, ARENA_MAX.y - 100)
		)

# Wywoływane przez scena_8.gd przy zmianie fazy
func ustaw_faze(faza: int):
	aktualna_faza = faza
	match faza:
		1:
			predkosc_bazowa = 120.0
			strzal_interwal = 1.0
			teleportacja_aktywna = false
		2:  # HP < 75%
			predkosc_bazowa = 160.0
			strzal_interwal = 0.9
			teleportacja_aktywna = true
			teleport_interwal = 5.0
		3:  # HP < 50%
			predkosc_bazowa = 210.0
			strzal_interwal = 0.8
			teleportacja_aktywna = true
			teleport_interwal = 3.0
		4:  # HP < 25%
			predkosc_bazowa = 280.0
			strzal_interwal = 0.6
			teleportacja_aktywna = true
			teleport_interwal = 2.0
