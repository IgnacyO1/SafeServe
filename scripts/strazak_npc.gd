extends CharacterBody2D
## Strażak NPC — idzie hardcoded trasą, gasi ogień, mówi voiceline, wraca i znika.

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_odejscia: Timer = $TimerOdejscia
@onready var timer_strzalu: Timer = $TimerStrzalu
@onready var voiceline_player: AudioStreamPlayer2D = $VoicelinePlayer

const POCISK_SCENA = preload("res://scenes/pocisk.tscn")

@export var predkosc: float = 250.0

# Hardcoded trasa NPC (z punktami pośrednimi dla płynności)
var trasa: Array = [
	Vector2(7500, 1100),
	Vector2(7500, 1058),
	Vector2(7500, 1015),
	Vector2(7362, 986),
	Vector2(7223, 956),
	Vector2(7064, 958),
	Vector2(6904, 960),
	Vector2(6886, 1112),
	Vector2(6867, 1264),
	Vector2(6846, 1416),
	Vector2(6825, 1567),
	Vector2(6825, 1727),
	Vector2(6825, 1898),
]

enum Stan { NIEAKTYWNY, CHODZENIE, GASIENIE, ODCHODZENIE, ZNIKANIE }
var stan: int = Stan.NIEAKTYWNY
var aktualny_punkt: int = 0

var ostatni_kierunek_idle = "dol"

func _ready():
	z_index = 10
	visible = false
	set_physics_process(false)
	anim_sprite.scale = Vector2(0.5, 0.5)
	anim_sprite.speed_scale = 3.0
	anim_sprite.play("strazak_idle_dol")

func aktywuj():
	stan = Stan.CHODZENIE
	visible = true
	set_physics_process(true)
	global_position = trasa[0]
	aktualny_punkt = 1
	timer_odejscia.start()

func _physics_process(delta):
	var scena = get_parent()
	if scena and scena.get("gra_aktywna") == false:
		velocity = Vector2.ZERO
		return

	match stan:
		Stan.CHODZENIE:
			_logika_chodzenia()
		Stan.GASIENIE:
			_logika_gasienia()
		Stan.ODCHODZENIE:
			_logika_odchodzenia()

# ---- Idź trasą do celu ----

func _logika_chodzenia():
	if aktualny_punkt >= trasa.size():
		# Dotarł na miejsce — stój i strzelaj
		stan = Stan.GASIENIE
		velocity = Vector2.ZERO
		timer_strzalu.start()
		return

	var cel = trasa[aktualny_punkt]
	var wektor = cel - global_position
	if wektor.length() < 30:
		aktualny_punkt += 1
		return
	velocity = wektor.normalized() * predkosc
	_update_animations(wektor.normalized())
	move_and_slide()

# ---- Stój na miejscu i strzelaj ----

func _logika_gasienia():
	velocity = Vector2.ZERO
	var ogien = _znajdz_najblizszy_ogien()
	if ogien and is_instance_valid(ogien):
		var dir_to_fire = (ogien.global_position - global_position).normalized()
		var angle = snappedf(dir_to_fire.angle(), PI / 4)
		match angle:
			0.0, PI / 4.0, -PI / 4.0:
				ostatni_kierunek_idle = "prawo"
			PI / 2.0:
				ostatni_kierunek_idle = "dol"
			3.0 * PI / 4.0, -3.0 * PI / 4.0, PI, -PI:
				ostatni_kierunek_idle = "lewo"
			-PI / 2.0:
				ostatni_kierunek_idle = "gora"
	_update_animations(Vector2.ZERO)
	move_and_slide()

# ---- Wracaj trasą w odwrotną stronę ----

func _logika_odchodzenia():
	if aktualny_punkt < 0:
		_zacznij_znikanie()
		return
	# Poza ekranem gracza → znikaj
	var gracze = get_tree().get_nodes_in_group("gracz")
	if gracze.size() > 0 and is_instance_valid(gracze[0]):
		if global_position.distance_to(gracze[0].global_position) > 800:
			_zacznij_znikanie()
			return

	var cel = trasa[aktualny_punkt]
	var wektor = cel - global_position
	if wektor.length() < 30:
		aktualny_punkt -= 1
		return
	velocity = wektor.normalized() * predkosc
	_update_animations(wektor.normalized())
	move_and_slide()

# ---- Animacja ----

func _update_animations(dir: Vector2):
	var anim_name = ""
	if dir == Vector2.ZERO:
		anim_name = "strazak_idle_" + ostatni_kierunek_idle
	else:
		# Matematyczne zaokrąglenie kąta do najbliższych 45 stopni (PI / 4)
		var angle = snappedf(dir.angle(), PI / 4)
		
		match angle:
			0.0: 
				anim_name = "strazak_chodzenie_prawo"
				ostatni_kierunek_idle = "prawo"
			PI / 4.0: 
				anim_name = "strazak_skos_dol_prawo"
				ostatni_kierunek_idle = "prawo"
			PI / 2.0: 
				anim_name = "strazak_chodzenie_dol"
				ostatni_kierunek_idle = "dol"
			3.0 * PI / 4.0: 
				anim_name = "strazak_skos_dol_lewo"
				ostatni_kierunek_idle = "lewo"
			PI, -PI: 
				anim_name = "strazak_chodzenie_lewo"
				ostatni_kierunek_idle = "lewo"
			-3.0 * PI / 4.0: 
				anim_name = "strazak_skos_gora_lewo"
				ostatni_kierunek_idle = "lewo"
			-PI / 2.0: 
				anim_name = "strazak_chodzenie_gora"
				ostatni_kierunek_idle = "gora"
			-PI / 4.0: 
				anim_name = "strazak_skos_gora_prawo"
				ostatni_kierunek_idle = "prawo"

	if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
		anim_sprite.play(anim_name)

func _znajdz_najblizszy_ogien():
	var ognie = get_tree().get_nodes_in_group("ogien")
	var najblizszy = null
	var min_d = INF
	for o in ognie:
		if is_instance_valid(o):
			var d = global_position.distance_to(o.global_position)
			if d < min_d:
				min_d = d
				najblizszy = o
	return najblizszy

# ---- Sygnały timerów ----

func _on_timer_strzalu_timeout():
	if stan != Stan.GASIENIE:
		return
	var cel = _znajdz_najblizszy_ogien()
	if cel and is_instance_valid(cel) and global_position.distance_to(cel.global_position) < 600:
		var pocisk = POCISK_SCENA.instantiate()
		get_parent().add_child(pocisk)
		pocisk.global_position = global_position
		pocisk.direction = (cel.global_position - global_position).normalized()

func _on_timer_odejscia_timeout():
	stan = Stan.ODCHODZENIE
	timer_strzalu.stop()
	if voiceline_player.stream:
		voiceline_player.play()
	# Zacznij wracać od przedostatniego punktu (jesteśmy na ostatnim)
	aktualny_punkt = trasa.size() - 2

func _zacznij_znikanie():
	stan = Stan.ZNIKANIE
	velocity = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	await tw.finished
	if is_instance_valid(self):
		visible = false
		set_physics_process(false)
