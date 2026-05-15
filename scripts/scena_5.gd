extends Control

@export var video_path: String = "res://assets/Videos/output.ogv"

var video_player: VideoStreamPlayer
var timeline_slider: HSlider
var play_pause_btn: Button
var status_label: Label
var reg_input: LineEdit

var video_duration: float = 1.0
var slider_update_in_progress: bool = false
var video_aspect_ratio: float = 16.0 / 9.0
var video_target_width: float = 0.0

var map_panel: Control
var map_dot: Polygon2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_target_width = get_viewport_rect().size.x * 0.5
	_build_ui()
	_setup_video()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	var video_center = CenterContainer.new()
	video_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(video_center)

	video_player = VideoStreamPlayer.new()
	video_player.expand = false
	video_player.custom_minimum_size = Vector2(video_target_width, video_target_width / video_aspect_ratio)
	video_player.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	video_player.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	video_center.add_child(video_player)

	# Ważne: Łączymy sygnał zakończenia filmu
	video_player.finished.connect(_on_video_finished)

	var controls_panel = PanelContainer.new()
	main_vbox.add_child(controls_panel)

	var controls_hb = HBoxContainer.new()
	controls_hb.custom_minimum_size.y = 60
	controls_panel.add_child(controls_hb)

	play_pause_btn = Button.new()
	play_pause_btn.text = " Odtwórz "
	play_pause_btn.custom_minimum_size.x = 120
	controls_hb.add_child(play_pause_btn)

	timeline_slider = HSlider.new()
	timeline_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	timeline_slider.custom_minimum_size.y = 30
	controls_hb.add_child(timeline_slider)

	var sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(250, 0)
	sidebar.position = Vector2(30, 30)
	add_child(sidebar)

	reg_input = LineEdit.new()
	reg_input.placeholder_text = "Numer rejestracyjny..."
	reg_input.custom_minimum_size.y = 40
	sidebar.add_child(reg_input)

	var search_btn = Button.new()
	search_btn.text = "SPRAWDŹ W BAZIE"
	search_btn.custom_minimum_size.y = 40
	sidebar.add_child(search_btn)

	status_label = Label.new()
	status_label.text = "System monitoringu aktywny."
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 6)
	sidebar.add_child(status_label)

	play_pause_btn.pressed.connect(_on_play_pause_toggled)
	timeline_slider.value_changed.connect(_on_timeline_changed)
	search_btn.pressed.connect(_on_search_pressed)
	
	_build_map_ui()

func _build_map_ui() -> void:
	map_panel = ColorRect.new()
	map_panel.color = Color(0, 0, 0, 0.85)
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_panel.hide()
	add_child(map_panel)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_panel.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var label = Label.new()
	label.text = "LOKALIZACJA POJAZDU NA MAPIE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(label)
	
	var map_texture = TextureRect.new()
	map_texture.texture = load("res://assets/graphics/Mapa krakow OSM.png")
	map_texture.custom_minimum_size = Vector2(800, 600)
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(map_texture)
	
	map_dot = Polygon2D.new()
	var pts = []
	for i in range(16):
		var angle = i * PI * 2 / 16.0
		pts.append(Vector2(cos(angle), sin(angle)) * 12.0)
	map_dot.polygon = PackedVector2Array(pts)
	map_dot.color = Color.RED
	map_texture.add_child(map_dot)
	
	var dispatch_btn = Button.new()
	dispatch_btn.text = "WYŚLIJ PATROL POLICYJNY"
	dispatch_btn.custom_minimum_size.y = 50
	dispatch_btn.add_theme_font_size_override("font_size", 24)
	dispatch_btn.pressed.connect(_on_dispatch_pressed)
	vbox.add_child(dispatch_btn)

func _setup_video() -> void:
	if FileAccess.file_exists(video_path):
		var stream = load(video_path)
		video_player.stream = stream
		video_player.play()
		video_player.paused = true
		
		await get_tree().create_timer(0.2).timeout
		video_duration = video_player.get_stream_length()
		if video_duration <= 0: video_duration = 1.0

		if video_player.stream and video_player.stream.has_method("get_width") and video_player.stream.has_method("get_height"):
			var width = video_player.stream.get_width()
			var height = video_player.stream.get_height()
			if width > 0 and height > 0:
				video_aspect_ratio = float(width) / float(height)
				video_player.custom_minimum_size = Vector2(video_target_width, video_target_width / video_aspect_ratio)
	else:
		status_label.text = "Błąd: Nie znaleziono pliku " + video_path

func _process(_delta: float) -> void:
	# Aktualizujemy pasek tylko gdy film faktycznie gra
	if video_player.is_playing() and not video_player.paused:
		slider_update_in_progress = true
		var progress = (video_player.stream_position / video_duration) * 100.0
		timeline_slider.value = clamp(progress, 0.0, 100.0)
		slider_update_in_progress = false

# Wywoływane automatycznie, gdy film dojdzie do końca
func _on_video_finished() -> void:
	video_player.paused = true
	play_pause_btn.text = " Odtwórz "
	status_label.text = "Koniec nagrania."

func _on_play_pause_toggled() -> void:
	# Jeśli film się skończył (is_playing jest false), odpalamy go od nowa
	if not video_player.is_playing():
		video_player.play()
	
	video_player.paused = !video_player.paused
	play_pause_btn.text = " Pauza " if !video_player.paused else " Odtwórz "

func _on_timeline_changed(value: float) -> void:
	if slider_update_in_progress: return
	
	var target_pos = (value / 100.0) * video_duration
	
	# KLUCZOWA POPRAWKA:
	# Jeśli film jest "zatrzymany" (bo się skończył), play() go zresetuje.
	# Potem ustawiamy pozycję i od razu pauzujemy, żeby nie leciał sam.
	if not video_player.is_playing():
		video_player.play()
	
	video_player.stream_position = target_pos
	
	# Jeśli przesuwamy pasek, zazwyczaj chcemy widzieć klatkę, ale w pauzie
	video_player.paused = true
	play_pause_btn.text = " Odtwórz "
	status_label.text = "Przeglądanie klatki: %0.1f s" % target_pos

func _on_search_pressed() -> void:
	var tekst = reg_input.text.to_upper().strip_edges()
	if tekst == "":
		status_label.text = "WPISZ NUMER!"
	else:
		status_label.text = "Analiza tablic: " + tekst
		map_panel.show()
		
		# Logika punktu na mapie
		if tekst == "KR4B2137":
			# Konkretna lokalizacja (symulacja ulicy Zawiłej)
			map_dot.position = Vector2(400, 480)
		else:
			# Losowa lokalizacja
			map_dot.position = Vector2(randf_range(100, 700), randf_range(100, 500))

func _on_dispatch_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scena_6.tscn")

func _input(event: InputEvent) -> void:
	# --- BACKDOOR DO TESTÓW ---
	# Odkomentuj poniższe linie, aby móc natychmiast przejść do Sceny 6 wciskając klawisz 'B'
	# if event is InputEventKey and event.pressed and event.keycode == KEY_B:
	# 	get_tree().change_scene_to_file("res://scenes/scena_6.tscn")
	pass
