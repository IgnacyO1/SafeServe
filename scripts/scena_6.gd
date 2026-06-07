extends Node2D

var gra_aktywna = true
var TramScene = preload("res://scenes/Metrotrain/Train.tscn")
# Załadowanie pliku dźwiękowego (podmień ścieżkę, jeśli plik jest w innym folderze)
var dzwiek_smierci = preload("res://assets/Sounds/dying.mp3") 

var timer_spawnu = 0.0
var interwal_spawnu = 10.0

@onready var gracz = $Gracz
@onready var spawn_point = $SpawnPoint
@onready var meta = $Meta

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
	if tor1 and tor1.curve and tor1.curve.point_count >= 2:
		var tram1 = TramScene.instantiate()
		add_child(tram1)
		tram1.init_from_path2d(tor1, 300.0)

	if tor2 and tor2.curve and tor2.curve.point_count >= 2:
		var tram2 = TramScene.instantiate()
		add_child(tram2)
		tram2.init_from_path2d(tor2, 300.0)

func gracz_trafiony():
	if not gra_aktywna:
		return
		
	_odtworz_dzwiek_smierci() # Uruchomienie dźwięku na samym początku
	_screen_shake(25.0)
	_spawn_krew_na_ekranie()
	
	if gracz:
		gracz.visible = false
		gracz.set_physics_process(false)
	
	await get_tree().create_timer(2.5).timeout
	
	if gracz and spawn_point:
		gracz.global_position = spawn_point.global_position
		gracz.visible = true
		gracz.set_physics_process(true)
		if "velocity" in gracz:
			gracz.velocity = Vector2.ZERO

func _odtworz_dzwiek_smierci():
	if not dzwiek_smierci:
		return
		
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = dzwiek_smierci
	add_child(audio_player)
	audio_player.play()
	
	# Automatyczne usunięcie odtwarzacza z pamięci po zakończeniu odtwarzania MP3
	audio_player.finished.connect(audio_player.queue_free)

func _spawn_krew_na_ekranie():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	var krew = CPUParticles2D.new()
	canvas_layer.add_child(krew)
	
	var screen_size = get_viewport().get_visible_rect().size
	krew.position = screen_size / 2.0
	
	krew.amount = 500
	krew.one_shot = true
	krew.explosiveness = 0.95
	krew.spread = 1500.0
	krew.gravity = Vector2(0, 400)
	
	krew.initial_velocity_min = 300.0
	krew.initial_velocity_max = 800.0
	krew.scale_amount_min = 8.0
	krew.scale_amount_max = 24.0
	
	krew.color = Color(0.75, 0.0, 0.0, 0.9)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.8, 0.0, 0.0, 1.0))
	gradient.set_color(1, Color(0.4, 0.0, 0.0, 0.0))
	krew.color_ramp = gradient
	
	krew.lifetime = 1.8
	
	# WYMUSZENIE EMISJI: Aktywuje cząsteczki stworzone dynamicznie
	krew.emitting = true 
	
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.6, 0.0, 0.0, 0.4)
	canvas_layer.add_child(flash)
	canvas_layer.move_child(flash, 0)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.6)
	
	get_tree().create_timer(2.2).timeout.connect(canvas_layer.queue_free)
	
func _on_meta_entered(body):
	if not gra_aktywna:
		return
	if body.is_in_group("gracz"):
		gra_aktywna = false
		get_tree().change_scene_to_file("res://scenes/scena_6ipol.tscn")

func _screen_shake(intensity: float):
	if not gracz:
		return
	var cam = gracz.get_node_or_null("Camera2D")
	if not cam:
		return
	var tw = create_tween()
	for i in range(10):
		tw.tween_property(cam, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)
