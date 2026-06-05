extends Node2D

var gra_aktywna = true
var TramScene = preload("res://scenes/Metrotrain/Train.tscn")
var timer_spawnu = 0.0
var interwal_spawnu = 15.0

@onready var gracz = $Gracz
@onready var spawn_point = $SpawnPoint
@onready var meta = $Meta

# Punkty startowe i końcowe torów — pobierane z Path2D w scenie
@onready var tor1 = $PociagiTrasy/Tor1
@onready var tor2 = $PociagiTrasy/Tor2

func _ready():
	_spawn_trains()
	if meta:
		meta.body_entered.connect(_on_meta_entered)

func _physics_process(delta):
	if not gra_aktywna:
		return
	timer_spawnu += delta
	if timer_spawnu >= interwal_spawnu:
		timer_spawnu = 0.0
		_spawn_trains()

func _spawn_trains():
	# Tor 1: pociąg jedzie z góry na dół
	if tor1 and tor1.curve and tor1.curve.point_count >= 2:
		var start1 = tor1.curve.get_point_position(0)
		var end1 = tor1.curve.get_point_position(tor1.curve.point_count - 1)
		var tram1 = TramScene.instantiate()
		add_child(tram1)
		tram1.init_straight_line(start1, end1, 100.0)

	# Tor 2: pociąg jedzie z dołu do góry
	if tor2 and tor2.curve and tor2.curve.point_count >= 2:
		var start2 = tor2.curve.get_point_position(0)
		var end2 = tor2.curve.get_point_position(tor2.curve.point_count - 1)
		var tram2 = TramScene.instantiate()
		add_child(tram2)
		tram2.init_straight_line(start2, end2, 100.0)

func gracz_trafiony():
	if not gra_aktywna:
		return
	_screen_shake(15.0)
	_spawn_krew()
	if gracz and spawn_point:
		gracz.global_position = spawn_point.global_position

func _spawn_krew():
	if not gracz:
		return
	var krew = CPUParticles2D.new()
	krew.emitting = false
	krew.amount = 30
	krew.one_shot = true
	krew.explosiveness = 1.0
	krew.direction = Vector2(0, -1)
	krew.spread = 180.0
	krew.initial_velocity_min = 100.0
	krew.initial_velocity_max = 300.0
	krew.color = Color(0.8, 0.0, 0.0, 1.0)
	krew.scale_amount_min = 3.0
	krew.scale_amount_max = 6.0
	krew.lifetime = 0.6
	krew.global_position = gracz.global_position
	add_child(krew)
	krew.restart()
	get_tree().create_timer(2.0).timeout.connect(krew.queue_free)

func _on_meta_entered(body):
	if not gra_aktywna:
		return
	if body.is_in_group("gracz"):
		gra_aktywna = false
		if ResourceLoader.exists("res://scenes/scena_7.tscn"):
			get_tree().change_scene_to_file("res://scenes/scena_7.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _screen_shake(intensity: float):
	if not gracz:
		return
	var cam = gracz.get_node_or_null("Camera2D")
	if not cam:
		return
	var tw = create_tween()
	for i in range(5):
		tw.tween_property(cam, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)
