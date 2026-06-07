extends Control

@export var video_path: String = "res://assets/Videos/output.ogv"
@export var json_path: String = "res://data/detections.json" # Ścieżka do Twojego JSON-a
# Referencje do istniejącego UI (zgodnie z Twoim nowym drzewem)
@onready var video_panel_container: PanelContainer = $CanvasLayer/VideoPanelContainer
@onready var btn_play: Button = $CanvasLayer/HBoxContainer/BtnPlay
@onready var h_slider: HSlider = $CanvasLayer/HBoxContainer/HSlider
@onready var time_label: Label = $CanvasLayer/HBoxContainer/TimeLabel

@onready var car_info_panel: PanelContainer = $CanvasLayer/CarInfoPanelContainer
@onready var car_info_text: RichTextLabel = $CanvasLayer/CarInfoPanelContainer/RichTextLabel
@onready var button_send: Button = $CanvasLayer/CarInfoPanelContainer/ButtonSend

# Elementy starego skryptu (mapa) generowane dynamicznie / zachowane
var map_panel: ColorRect
var map_dot: Polygon2D
var dispatch_btn: Button
var map_title_label: Label

# Odtwarzacz wideo i warstwa na ramki YOLO
var video_player: VideoStreamPlayer
var bbox_container: Control

# Zmienne logiczne
var video_duration: float = 1.0
var slider_update_in_progress: bool = false
var video_orig_width: float = 720.0
var video_orig_height: float = 576.0
var current_selected_plate: String = ""

# Dane z JSON
var json_data: Dictionary = {}
var start_timestamp: int = 34239 # 09:30:39 w sekundach od północy

# Kolory
const COLOR_BG = Color("#15053d")
const COLOR_SIDEBAR = Color("#2a1863")
const COLOR_PRIMARY = Color("#004e9e")
const COLOR_PRIMARY_HOVER = Color("#2c7bc4")
const COLOR_ACCENT = Color("#008bc2")
const COLOR_TEXT = Color("#8eb5de")
const COLOR_SUCCESS = Color("#545917")
const COLOR_WARNING = Color("#d66d00")
const COLOR_ERROR = Color("#a82a30")

# Baza zmyślonych właścicieli i adresów
var mock_owners: Dictionary = {
	"KR4B2137": {"name": "BRAK", "address": "Lipińskiego 1", "risk": "WYSOKIE", "color": "#a82a30"},
	"KR64607": {"name": "Jan Kowalski", "address": "Pawia 5, Kraków", "risk": "Niskie", "color": "#545917"}
}

func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_5.tscn")
	
	# Ukrywamy panel info na starcie
	car_info_panel.hide()
	
	_load_json_data()
	_setup_video_player()
	_setup_ui_signals()
	_build_map_ui() # Zachowane stare okno mapy

func _load_json_data() -> void:
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var json = JSON.new()
		if json.parse(json_text) == OK:
			json_data = json.get_data()
			if json_data.has("width"): video_orig_width = json_data["width"]
			if json_data.has("height"): video_orig_height = json_data["height"]
	else:
		print("Błąd: Nie znaleziono pliku JSON z danymi YOLO: ", json_path)

func _setup_video_player() -> void:
	# 1. Tworzymy VideoStreamPlayer wewnątrz VideoPanelContainer
	video_player = VideoStreamPlayer.new()
	video_player.expand = true
	video_player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video_player.size_flags_vertical = Control.SIZE_EXPAND_FILL
	video_panel_container.add_child(video_player)
	
	# 2. Tworzymy kontener na ramki jako DZIECKO odtwarzacza wideo lub PO NIM,
	# aby rysował się na samym wierzchu.
	bbox_container = Control.new()
	# Wymuszamy, aby kontener idealnie podążał za rozmiarem wideo
	bbox_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bbox_container.mouse_filter = Control.MOUSE_FILTER_PASS # Pozwala klikać przez niego
	video_panel_container.add_child(bbox_container)
	
	if FileAccess.file_exists(video_path):
		video_player.stream = load(video_path)
		video_player.play()
		video_player.paused = true
		
		await get_tree().create_timer(0.2).timeout
		video_duration = video_player.get_stream_length()
		if video_duration <= 0: video_duration = 1.0
	else:
		print("Błąd: Brak pliku wideo.")

func _setup_ui_signals() -> void:
	btn_play.pressed.connect(_on_play_pause_toggled)
	h_slider.value_changed.connect(_on_timeline_changed)
	video_player.finished.connect(_on_video_finished)
	button_send.pressed.connect(_on_button_send_pressed)

func _process(_delta: float) -> void:
	if video_player.is_playing() and not video_player.paused:
		slider_update_in_progress = true
		var progress = (video_player.stream_position / video_duration) * 100.0
		h_slider.value = clamp(progress, 0.0, 100.0)
		slider_update_in_progress = false
	_update_time_label(video_player.stream_position)
	_update_bounding_boxes(video_player.stream_position)

func _update_time_label(current_stream_time: float) -> void:
	var total_seconds = start_timestamp + int(current_stream_time)
	var hrs = (total_seconds / 3600) % 24
	var mins = (total_seconds / 60) % 60
	var secs = total_seconds % 60
	time_label.text = "%02d:%02d:%02d" % [hrs, mins, secs]

func _update_bounding_boxes(current_time: float) -> void:
	# Czyszczenie starych ramek
	for child in bbox_container.get_children():
		child.queue_free()
		
	if not json_data.has("vehicles"): return
	
	var container_size = bbox_container.size
	# Skala mapowania pozycji z 720x576 do obecnego rozmiaru PanelContainer
	var scale_x = container_size.x / video_orig_width
	var scale_y = container_size.y / video_orig_height
	
	for plate in json_data["vehicles"]:
		var car_data = json_data["vehicles"][plate]
		if not car_data.has("positions"): continue
		
		# Szukamy pozycji najbliższej aktualnemu czasowi wideo
		var best_pos = null
		var min_diff = 0.5 # Tolerancja czasu klatki (ok. 2 klatki przy 25 FPS)
		
		for pos in car_data["positions"]:
			var diff = abs(pos["time"] - current_time)
			if diff < min_diff:
				min_diff = diff
				best_pos = pos
				
		if best_pos != null:
			_create_bbox_ui(plate, best_pos, scale_x, scale_y)

func _create_bbox_ui(plate: String, pos: Dictionary, scale_x: float, scale_y: float) -> void:
	var box = ReferenceRect.new()
	
	# Kolorowanie ramek
	box.border_color = Color.GREEN
	if plate == "KR4B2137": 
		box.border_color = Color.RED
	
	box.border_width = 3.0 # Zwiększamy grubość, żeby była wyraźna
	box.editor_only = false # KLUCZOWE: Inaczej nie rysuje się w buildzie gry
	
	# Blokujemy domyślne zachowanie pochłaniania myszki przez ReferenceRect, 
	# aby sygnał hover działał bezbłędnie
	box.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# Pozycja i rozmiar przeskalowane do obecnego, fizycznego rozmiaru okna wideo
	box.position = Vector2(pos["x"] * scale_x, pos["y"] * scale_y)
	box.size = Vector2(pos["width"] * scale_x, pos["height"] * scale_y)
	
	# Label z numerem rejestracyjnym nad ramką
	var label = Label.new()
	label.text = plate
	label.position = Vector2(0, -22)
	label.add_theme_color_override("font_color", box.border_color)
	label.add_theme_font_size_override("font_size", 14)
	
	# Dodajemy czarne tło pod napis, żeby był czytelny na ruchomym wideo
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	sb.set_content_margin_all(2)
	label.add_theme_stylebox_override("normal", sb)
	
	box.add_child(label)
	
	# Wykrywanie najechania myszką (Hover)
	box.mouse_entered.connect(_on_car_hovered.bind(plate))
	
	bbox_container.add_child(box)

func _on_car_hovered(plate: String) -> void:
	current_selected_plate = plate
	
	# Pobieramy dane (jeśli nie ma w bazie, generujemy zmyślone)
	var owner = "Nieznany"
	var address = "Brak danych w bazie miejskiej"
	var risk = "Niskie"
	var risk_color = "#545917"
	 
	if mock_owners.has(plate):
		owner = mock_owners[plate]["name"]
		address = mock_owners[plate]["address"]
		risk = mock_owners[plate]["risk"]
		risk_color = mock_owners[plate]["color"]
	else:
		# Generowanie losowych danych dla reszty aut z JSON
		owner = "Mieszkaniec nr " + str(randi() % 1000)
		address = "ul. Reymonta " + str(randi() % 50 + 1) + ", Kraków"
	
	# Budowanie tekstu dla RichTextLabel
	car_info_text.clear()
	car_info_text.append_text("[b]POJAZD ZIDENTYFIKOWANY[/b]\n")
	car_info_text.append_text("Tablica: [color=yellow]" + plate + "[/color]\n")
	car_info_text.append_text("Właściciel: " + owner + "\n")
	car_info_text.append_text("Podejrzenie: [color=" + risk_color + "]" + risk.to_upper() + "[/color]\n")
	car_info_text.append_text("Ostatnio widziany: " + address)
	
	car_info_panel.show()

func _on_button_send_pressed() -> void:
	# Pokazujemy stare okno mapy po kliknięciu wyślij
	map_panel.show()
	_style_button(dispatch_btn, COLOR_WARNING, COLOR_PRIMARY_HOVER)
	dispatch_btn.disabled = false
	dispatch_btn.text = "POTWIERDŹ WYSŁANIE PATROLU"
	
	if current_selected_plate == "KR4B2137":
		map_title_label.text = "LOKALIZACJA: Lipińskiego 1 (ZAGROŻENIE WYSOKIE)"
		map_dot.position = Vector2(260, 490) # Konkretny punkt
	else:
		map_title_label.text = "LOKALIZACJA: Parking Główny Sector B"
		map_dot.position = Vector2(randf_range(200, 600), randf_range(200, 400))

# --- OBSŁUGA WIDEO I INTERFEJSU ---

func _on_play_pause_toggled() -> void:
	if not video_player.is_playing():
		video_player.play()
	video_player.paused = !video_player.paused
	btn_play.text = " Pauza " if !video_player.paused else " Odtwórz "

func _on_timeline_changed(value: float) -> void:
	if slider_update_in_progress: return
	var target_pos = (value / 100.0) * video_duration
	if not video_player.is_playing():
		video_player.play()
	video_player.stream_position = target_pos
	video_player.paused = true
	btn_play.text = " Odtwórz "

func _on_video_finished() -> void:
	video_player.paused = true
	btn_play.text = " Odtwórz "

# --- STARE OKNO MAPY (ZACHOWANA LOGIKA I ZMIANA SCENY) ---

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

func _on_dispatch_pressed() -> void:
	if current_selected_plate == "KR4B2137":
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

func _on_close_map_pressed() -> void:
	map_panel.hide()

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
