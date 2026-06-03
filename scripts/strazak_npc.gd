extends CharacterBody2D
## Strażak NPC — idzie hardcoded trasą, gasi ogień, mówi voiceline, wraca i znika.

@onready var sprite: Sprite2D = $Sprite2D
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

# Animacja
var anim_timer: float = 0.0
var current_anim_frames: int = 1
var current_frame_idx: int = 0
var last_dir_str: String = "down"

var textures_idle = {
	"up": preload("res://assets/graphics/scena3_animacja_ruchu/idle_gora.png"),
	"down": preload("res://assets/graphics/scena3_animacja_ruchu/idle_dol.png"),
	"left": preload("res://assets/graphics/scena3_animacja_ruchu/idle_lewo.png"),
	"right": preload("res://assets/graphics/scena3_animacja_ruchu/idle_prawo.png"),
}
var textures_walk = {
	"up": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_gora.png"),
	"down": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_dol.png"),
	"left": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_lewo1.png"),
	"right": preload("res://assets/graphics/scena3_animacja_ruchu/chodzenie_prawover1.png"),
}
var frame_counts_walk = { "up": 4, "down": 4, "left": 3, "right": 3 }

func _ready():
	z_index = 10
	visible = false
	set_physics_process(false)
	_ustaw_animacje("idle", "down")

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

	if current_anim_frames > 1:
		anim_timer += delta
		if anim_timer >= 0.15:
			anim_timer -= 0.15
			current_frame_idx = (current_frame_idx + 1) % current_anim_frames
			sprite.frame = current_frame_idx

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
	_aktualizuj_kierunek(wektor.normalized(), "walk")
	move_and_slide()

# ---- Stój na miejscu i strzelaj ----

func _logika_gasienia():
	velocity = Vector2.ZERO
	var ogien = _znajdz_najblizszy_ogien()
	if ogien and is_instance_valid(ogien):
		_aktualizuj_kierunek((ogien.global_position - global_position).normalized(), "idle")
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
	_aktualizuj_kierunek(wektor.normalized(), "walk")
	move_and_slide()

# ---- Animacja ----

func _aktualizuj_kierunek(kierunek: Vector2, state: String):
	if kierunek.length() < 0.1:
		return
	var dir_str: String
	if abs(kierunek.x) > abs(kierunek.y):
		dir_str = "right" if kierunek.x > 0 else "left"
	else:
		dir_str = "down" if kierunek.y > 0 else "up"
	last_dir_str = dir_str
	_ustaw_animacje(state, dir_str)

func _ustaw_animacje(state: String, dir_str: String):
	var tex
	if state == "walk":
		tex = textures_walk.get(dir_str, textures_walk["down"])
	else:
		tex = textures_idle.get(dir_str, textures_idle["down"])
	if sprite.texture != tex:
		sprite.texture = tex
		var frames = 1
		if state == "walk" and frame_counts_walk.has(dir_str):
			frames = frame_counts_walk[dir_str]
		sprite.hframes = frames
		sprite.vframes = 1
		current_anim_frames = frames
		current_frame_idx = 0
		sprite.frame = 0
		anim_timer = 0.0

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
