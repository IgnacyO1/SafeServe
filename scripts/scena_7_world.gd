extends Node2D

# Unikalne USTAWIENIA TEJ TRASY
var start_pos_px = Vector2(-18030+randf(), 50850+randf())
var cutscene_path = "res://assets/Videos/spin.ogv" # to trzeba zmienić tzn dodać cutscenę jak cyberkrab wychodzi z samochodu

@onready var player = $Police
@onready var map_manager = $MapManager

var coords_label: Label
var arrow_sprite: Polygon2D
var fade_rect: ColorRect
var night_overlay: ColorRect
var video_player: VideoStreamPlayer
var is_changing_scene = false
var uciekinier = true

func _ready():
	if not player: return
	if map_manager:
		map_manager.night_mode = true
	setup_level()
	setup_ui()

	
func setup_level():
	if map_manager:
		map_manager.initialize_map(start_pos_px)
	
	var tm = get_node_or_null("Traffic Manager")
	if tm:
		# Ważne: setup_mode wywołujemy po initialize_map
		tm.setup_mode(true)

func _process(_delta):
	if is_changing_scene: return
	
	var boss = get_tree().get_first_node_in_group("uciekinier")
	
	if is_instance_valid(boss):
		var dist_to_boss = player.global_position.distance_to(boss.global_position)
		var dist_m = dist_to_boss / 20.0
		get_tree().current_scene.map.set_player(player.global_position, player.rotation)
		get_tree().current_scene.map.set_target(boss.global_position)

		# Strzałka na uciekiniera
		var dist_vec = boss.global_position - player.global_position
		arrow_sprite.rotation = dist_vec.angle() - player.rotation
		
		coords_label.text = "POŚCIG ZA CYBERKRABEM\nDYSTANS: %d m" % int(dist_m)

		# Nowy WARUNEK ZŁAPANIA (NA PODSTAWIE REAL_SPEED)
		# Przerywnik odpali się, jeśli:
		# a) Jesteś blisko (< 7m) I uciekinier fizycznie utknął / stoi (real_speed < 30.0)
		# b) LUB uciekinier dojechał do samego końca trasy (boss.speed == 0)
		
		var is_close_and_blocked = (dist_m < 7.0 and boss.real_speed < 30.0)
		var reached_end_of_path = (boss.speed == 0.0)

		if is_close_and_blocked or reached_end_of_path:
			play_cutscene_sequence()
	else:
		coords_label.text = "SZUKANIE SYGNAŁU..."
		# Jeśli bossa nie ma, strzałka może się kręcić albo być ukryta

func setup_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	night_overlay = ColorRect.new()
	night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night_overlay.color = Color(0.04, 0.10, 0.18, 0.36)
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_overlay.z_index = -5
	canvas.add_child(night_overlay)
	
	# [KOD LABELA I STRZAŁKI BEZ ZMIAN]
	coords_label = Label.new()
	coords_label.position = Vector2(20, 20)
	coords_label.add_theme_font_size_override("font_size", 24)
	coords_label.modulate = Color(0.8, 0.95, 1.0, 1.0)
	canvas.add_child(coords_label)
	
	var arrow_container = Marker2D.new()
	arrow_container.position = Vector2(get_viewport_rect().size.x - 100, 100)
	canvas.add_child(arrow_container)
	
	arrow_sprite = Polygon2D.new()
	arrow_sprite.polygon = PackedVector2Array([Vector2(0, -25), Vector2(15, 15), Vector2(0, 5), Vector2(-15, 15)])
	arrow_sprite.color = Color(0.8, 0.9, 1.0, 1.0)
	arrow_container.add_child(arrow_sprite)

	video_player = VideoStreamPlayer.new()
	video_player.stream = load(cutscene_path)
	video_player.expand = true
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.modulate.a = 0 # Ukryty na początku
	canvas.add_child(video_player)
	
	# Czarny ekran (na samej górze, layer 100 i ostatni child w canvas)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_rect)



func play_cutscene_sequence():
	is_changing_scene = true
	
	get_tree().current_scene.radio.visible = false
	# Ściemnienie gry (Fade Out)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	
	await tween.finished # Czekamy aż zgaśnie
	
	# Przygotowanie wideo pod czarną zasłoną
	video_player.modulate.a = 1.0
	video_player.play()
	
	# Rozjaśnienie wideo (Fade In wideo)
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	
	# Czekamy aż film się skończy (lub używamy timer na 2s)
	await get_tree().create_timer(2.0).timeout
	
	# Ściemnienie wideo (Fade Out przed zmianą sceny)
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	
	await tween_out.finished
	get_tree().change_scene_to_file("res://scenes/scena_8.tscn")

# func _input(event):
	# # Zmieniono z is_action_just_pressed na is_action_pressed
	# # Dodajemy 'false' jako drugi argument, aby ignorowało przytrzymanie klawisza (echo)
	# if event.is_action_pressed("ui_accept", false):
		# log_current_coordinates()
#
# func log_current_coordinates():
	# if is_instance_valid(player):
		# var pos = player.global_position
		# # round() sprawi, że koordynaty będą czyste i gotowe do wklejenia
		# var clean_x = round(pos.x)
		# var clean_y = round(pos.y)
		# print("Vector2(%d, %d)," % [clean_x, clean_y])
