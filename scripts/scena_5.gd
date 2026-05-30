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
var dispatch_btn: Button
var map_title_label: Label

# Definicje stonowanych kolorów Motorola Corporate Identity (Przyciemnione o 15-20%)
const COLOR_BG = Color("#15053d")              # Przyciemniony Midnight Blue shade
const COLOR_SIDEBAR = Color("#2a1863")         # Przyciemniony Core Midnight Blue
const COLOR_PRIMARY = Color("#004e9e")         # Przyciemniony Core Dark Blue
const COLOR_PRIMARY_HOVER = Color("#2c7bc4")   # Stonowany hover
const COLOR_ACCENT = Color("#008bc2")          # Przyciemniony Core Light Blue
const COLOR_TEXT = Color("#8eb5de")            # Mniej jaskrawy jasnoniebieski tekst
const COLOR_SUCCESS = Color("#545917")         # Stonowany Core Dark Green
const COLOR_WARNING = Color("#d66d00")         # Stonowany Core Orange
const COLOR_ERROR = Color("#a82a30")           # Stonowany Core Red

var plates: Dictionary = {
	1: "KR 4JX21", 2: "KRA 91PF", 3: "KK 7L221", 4: "WX 7788K", 5: "GD 52LA",
	6: "PO 8CE44", 7: "DW 31KF", 10: "LU 4H882", 12: "EL 93PK", 13: "KR 7AT11",
	22: "ZS 1LE92", 42: "KGR 4X221", 49: "SCI 88FK", 55: "KLI 2PA77", 58: "KR 91UU2",
	59: "WA 7CC31", 68: "KR 6M882", 96: "KRA 22EF", 106: "SK 52XA", 120: "DW 8L992",
	158: "GD 71PA", 205: "PO 44CX2", 300: "KR 8XY11", 313: "WA 3EE88", 324: "LU 5KK21",
	345: "EL 991LA", 389: "ZS 7TR55", 392: "SCI 2AC11", 
	543: "KR4B2137",
	558: "KGR 8PF22", 561: "DW 5AF81", 572: "PO 3CE77", 574: "GD 1XP42"
}

func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_5.tscn")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_target_width = get_viewport_rect().size.x * 0.5
	_build_ui()
	_setup_video()

func _build_ui() -> void:
	# Główny panel tła - rysuje się pod wszystkim, na absolutny pełny ekran
	var bg = ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Globalny margines (Padding) dla całego interfejsu użytkownika
	var global_margin = MarginContainer.new()
	global_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	global_margin.add_theme_constant_override("margin_top", 60)
	global_margin.add_theme_constant_override("margin_bottom", 60)
	global_margin.add_theme_constant_override("margin_left", 20)
	global_margin.add_theme_constant_override("margin_right", 20)
	add_child(global_margin)

	# Podział ekranu wewnątrz marginesów
	var main_split = HSplitContainer.new()
	main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.split_offset = int(get_viewport_rect().size.x * 0.72)
	global_margin.add_child(main_split)

	# Sekcja Lewa: Układ pionowy dla odtwarzacza i paska kontrolnego
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 15)
	main_split.add_child(left_vbox)

	var video_center = CenterContainer.new()
	video_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(video_center)

	video_player = VideoStreamPlayer.new()
	video_player.expand = false
	video_player.custom_minimum_size = Vector2(video_target_width, video_target_width / video_aspect_ratio)
	video_center.add_child(video_player)
	video_player.finished.connect(_on_video_finished)

	# Dolny panel kontrolny wideo
	var controls_panel = PanelContainer.new()
	var cp_style = StyleBoxFlat.new()
	cp_style.bg_color = COLOR_SIDEBAR
	cp_style.set_content_margin_all(15)
	cp_style.set_corner_radius_all(6)
	controls_panel.add_theme_stylebox_override("panel", cp_style)
	left_vbox.add_child(controls_panel)

	var controls_hb = HBoxContainer.new()
	controls_hb.add_theme_constant_override("separation", 15)
	controls_panel.add_child(controls_hb)

	play_pause_btn = Button.new()
	play_pause_btn.text = " Odtwórz "
	play_pause_btn.custom_minimum_size = Vector2(120, 40)
	_style_button(play_pause_btn, COLOR_PRIMARY, COLOR_PRIMARY_HOVER)
	controls_hb.add_child(play_pause_btn)

	timeline_slider = HSlider.new()
	timeline_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(timeline_slider)
	controls_hb.add_child(timeline_slider)

	# Sekcja Prawa: Panel Boczny (Sidebar)
	var sidebar_panel = PanelContainer.new()
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = COLOR_SIDEBAR
	sb_style.set_border_width_all(2)
	sb_style.border_color = COLOR_ACCENT
	sb_style.set_content_margin_all(20)
	sb_style.set_corner_radius_all(6)
	sidebar_panel.add_theme_stylebox_override("panel", sb_style)
	main_split.add_child(sidebar_panel)

	var sidebar = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 20)
	sidebar_panel.add_child(sidebar)

	var sidebar_title = Label.new()
	sidebar_title.text = "KONTROLA DOSTĘPU"
	sidebar_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sidebar_title.add_theme_font_size_override("font_size", 18)
	sidebar_title.add_theme_color_override("font_color", COLOR_ACCENT)
	sidebar.add_child(sidebar_title)

	reg_input = LineEdit.new()
	reg_input.placeholder_text = "Numer rejestracyjny..."
	reg_input.custom_minimum_size.y = 45
	reg_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_line_edit(reg_input)
	sidebar.add_child(reg_input)

	var search_btn = Button.new()
	search_btn.text = "SPRAWDŹ W BAZIE"
	search_btn.custom_minimum_size.y = 45
	_style_button(search_btn, COLOR_PRIMARY, COLOR_PRIMARY_HOVER)
	sidebar.add_child(search_btn)

	var separator = ColorRect.new()
	separator.custom_minimum_size.y = 2
	separator.color = COLOR_PRIMARY
	sidebar.add_child(separator)

	status_label = Label.new()
	status_label.text = "System monitoringu aktywny."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", COLOR_TEXT)
	sidebar.add_child(status_label)

	play_pause_btn.pressed.connect(_on_play_pause_toggled)
	timeline_slider.value_changed.connect(_on_timeline_changed)
	search_btn.pressed.connect(_on_search_pressed)
	
	_build_map_ui()

func _build_map_ui() -> void:
	map_panel = ColorRect.new()
	map_panel.color = Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, 0.96)
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_panel.hide()
	add_child(map_panel)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_panel.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	center.add_child(vbox)
	
	map_title_label = Label.new()
	map_title_label.text = "Lokalizacja pojazdu"
	map_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_title_label.add_theme_font_size_override("font_size", 28)
	map_title_label.add_theme_color_override("font_color", COLOR_TEXT)
	vbox.add_child(map_title_label)
	
	var map_container = PanelContainer.new()
	var mc_style = StyleBoxFlat.new()
	mc_style.bg_color = Color.BLACK
	mc_style.set_border_width_all(3)
	mc_style.border_color = COLOR_ACCENT
	mc_style.set_corner_radius_all(6)
	map_container.add_theme_stylebox_override("panel", mc_style)
	vbox.add_child(map_container)

	var map_texture = TextureRect.new()
	map_texture.texture = load("res://assets/graphics/Mapa krakow OSM.png")
	map_texture.custom_minimum_size = Vector2(800, 550)
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_container.add_child(map_texture)
	
	map_dot = Polygon2D.new()
	var pts = []
	for i in range(16):
		var angle = i * PI * 2 / 16.0
		pts.append(Vector2(cos(angle), sin(angle)) * 10.0)
	map_dot.polygon = PackedVector2Array(pts)
	map_dot.color = COLOR_ERROR
	map_texture.add_child(map_dot)
	
	dispatch_btn = Button.new()
	dispatch_btn.text = "WYŚLIJ PATROL POLICYJNY"
	dispatch_btn.custom_minimum_size.y = 50
	dispatch_btn.add_theme_font_size_override("font_size", 20)
	_style_button(dispatch_btn, COLOR_WARNING, COLOR_PRIMARY_HOVER)
	# NAPRAWIONE: Dodane połączenie sygnału, które wcześniej zniknęło!
	dispatch_btn.pressed.connect(_on_dispatch_pressed)
	vbox.add_child(dispatch_btn)

	var close_btn = Button.new()
	close_btn.text = " X "
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-75, 30) 
	close_btn.add_theme_font_size_override("font_size", 22)
	_style_button(close_btn, COLOR_ERROR, COLOR_ERROR.darkened(0.2))
	map_panel.add_child(close_btn)
	close_btn.pressed.connect(_on_close_map_pressed)

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
	if video_player.is_playing() and not video_player.paused:
		slider_update_in_progress = true
		var progress = (video_player.stream_position / video_duration) * 100.0
		timeline_slider.value = clamp(progress, 0.0, 100.0)
		slider_update_in_progress = false

func _on_video_finished() -> void:
	video_player.paused = true
	play_pause_btn.text = " Odtwórz "
	status_label.text = "Koniec nagrania."

func _on_play_pause_toggled() -> void:
	if not video_player.is_playing():
		video_player.play()
	
	video_player.paused = !video_player.paused
	play_pause_btn.text = " Pauza " if !video_player.paused else " Odtwórz "

func _on_timeline_changed(value: float) -> void:
	if slider_update_in_progress: return
	
	var target_pos = (value / 100.0) * video_duration
	if not video_player.is_playing():
		video_player.play()
	
	video_player.stream_position = target_pos
	video_player.paused = true
	play_pause_btn.text = " Odtwórz "
	status_label.text = "Przeglądanie klatki: %0.1f s" % target_pos

func _on_search_pressed() -> void:
	var tekst = reg_input.text.to_upper().replace(" ", "").strip_edges()
	if tekst == "":
		status_label.text = "WPISZ NUMER!"
		return

	var znaleziono_dokladnie = false
	var najblizsza_sugestia = ""
	var min_roznica = 99

	for klucz in plates:
		var baza_numer = plates[klucz].to_upper().replace(" ", "")
		if tekst == baza_numer:
			znaleziono_dokladnie = true
			break
			
		var roznica = _oblicz_roznice(tekst, baza_numer)
		if roznica < min_roznica:
			min_roznica = roznica
			najblizsza_sugestia = plates[klucz]

	if znaleziono_dokladnie:
		status_label.text = "Analiza tablic: " + tekst
		map_panel.show()
		
		_style_button(dispatch_btn, COLOR_WARNING, COLOR_PRIMARY_HOVER)
		dispatch_btn.disabled = false
		dispatch_btn.text = "WYŚLIJ PATROL POLICYJNY"
		
		var godzina_tekst = ""
		if tekst == "KR4B2137":
			godzina_tekst = "09:59"
			map_dot.position = Vector2(260, 490)
		else:
			var losowa_godzina = randi() % 24
			var losowa_minuta = randi() % 60
			godzina_tekst = "%02d:%02d" % [losowa_godzina, losowa_minuta]
			map_dot.position = Vector2(randf_range(100, 700), randf_range(100, 500))
		
		map_title_label.text = "OSTATNI REKORD W BAZIE KAMER MIEJSKICH (" + godzina_tekst + ")"
		
	elif min_roznica <= 2:
		status_label.text = "Brak pojazdu. Czy chodziło o: " + najblizsza_sugestia + "?"
	else:
		status_label.text = "Nie odnaleziono takiego samochodu w bazie danych."

func _oblicz_roznice(s1: String, s2: String) -> int:
	var roznice = abs(s1.length() - s2.length())
	var min_len = min(s1.length(), s2.length())
	for i in range(min_len):
		if s1[i] != s2[i]:
			roznice += 1
	return roznice
	
func _on_dispatch_pressed() -> void:
	var tekst = reg_input.text.to_upper().replace(" ", "").strip_edges()
	
	if tekst == "KR4B2137":
		get_tree().change_scene_to_file("res://scenes/scena_7.tscn")
	else:
		dispatch_btn.disabled = true
		
		dispatch_btn.text = "ŁADOWANIE..."
		await get_tree().create_timer(1.5).timeout
		
		dispatch_btn.text = "PATROL JEDZIE NA MIEJSCE"
		map_title_label.text = "STATUS: W TOKU INTERWENCJI..."
		await get_tree().create_timer(2.0).timeout
		
		_style_button(dispatch_btn, COLOR_SUCCESS, COLOR_SUCCESS)
		dispatch_btn.text = "PATROL NIE ZNALAZŁ NIC PODEJRZANEGO"
		map_title_label.text = "STATUS: FAŁSZYWY ALARM"
		status_label.text = "Raport: Brak podejrzanego pojazdu pod wskazanym adresem. Przeanalizuj nagranie z monitoringu."

func _on_close_map_pressed() -> void:
	map_panel.hide()
	if not dispatch_btn.disabled:
		status_label.text = "System monitoringu aktywny."

# Pomocnicze FUNKCJE STYLIZOWANIA UI SYSTEMOWEGO (MOTOROLA DESIGN)
func _style_button(btn: Button, bg_col: Color, hover_col: Color) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_col
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(10)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = hover_col
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(10)
	
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = bg_col.darkened(0.4)
	disabled.set_corner_radius_all(6)
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _style_line_edit(le: LineEdit) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("352f33ff") # Dodatkowo przyciemniony wkład tekstowy
	style.set_border_width_all(2)
	style.border_color = COLOR_PRIMARY
	style.set_corner_radius_all(6)
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_color_override("font_color", Color.WHITE)

func _style_slider(slider: HSlider) -> void:
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color("#003063")
	slider_style.expand_margin_top = 4
	slider_style.expand_margin_bottom = 4
	slider_style.set_corner_radius_all(4)
	
	slider.add_theme_stylebox_override("slider", slider_style)
