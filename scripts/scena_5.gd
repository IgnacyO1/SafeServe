extends Node2D

@onready var video_player = $UI/VideoPlayer
@onready var timeline_slider = $UI/Panel/TimelineSlider
@onready var timer_label = $UI/Panel/TimerLabel
@onready var motorola_button = $UI/Panel/MotorolaButton
@onready var database_panel = $UI/DatabasePanel
@onready var face_scan_rect = $UI/VideoPlayer/FaceScanRect
@onready var play_pause_btn = $UI/Panel/PlayPauseButton
@onready var win_screen = $UI/WinScreen
@onready var fail_screen = $UI/FailScreen

var total_time = 45.0
var time_left = 45.0
var is_playing = false
var is_scanning = false
var game_over = false

# Preload textures (adjust paths if needed)
var normal_texture = preload("res://assets/graphics/scena5_frame_normal.png")
var suspect_texture = preload("res://assets/graphics/scena5_frame_suspect.png")

# The suspect appears between these timeline values
var suspect_start = 60.0
var suspect_end = 80.0

func _ready():
	timeline_slider.value = 0
	time_left = total_time
	# Configure VideoStreamPlayer instead of TextureRect
	# Ensure the video is playing but paused at start
	video_player.stream = preload("res://assets/graphics/scena5_wideo.ogv")
	video_player.play()
	video_player.paused = true
	
	face_scan_rect.hide()
	database_panel.hide()
	win_screen.hide()
	fail_screen.hide()
	
	play_pause_btn.pressed.connect(_on_play_pause_pressed)
	timeline_slider.value_changed.connect(_on_timeline_changed)
	motorola_button.pressed.connect(_on_motorola_tool_pressed)
	
	# Connect database buttons
	$UI/DatabasePanel/VBoxContainer/SuspectButton.pressed.connect(func(): _on_suspect_selected(true))
	$UI/DatabasePanel/VBoxContainer/WrongButton1.pressed.connect(func(): _on_suspect_selected(false))
	$UI/DatabasePanel/VBoxContainer/WrongButton2.pressed.connect(func(): _on_suspect_selected(false))
	
	call_deferred("show_tutorial")

func _process(delta):
	if game_over: return

	if is_playing:
		time_left -= delta
		if time_left <= 0:
			fail_scene("Czas minął! Nie udało ci się namierzyć podejrzanego.")
			return
			
		if is_playing:
			timeline_slider.value = (video_player.stream_position / 8.0) * 100.0 # 8 seconds video
			if video_player.stream_position >= 7.9: # loop or pause at end
				video_player.paused = true
				is_playing = false
				play_pause_btn.text = "Graj"

	update_timer_ui()

func update_timer_ui():
	timer_label.text = "Czas: " + str(int(time_left)) + "s"

func _on_play_pause_pressed():
	if game_over: return
	is_playing = !is_playing
	video_player.paused = !is_playing
	play_pause_btn.text = "Pauza" if is_playing else "Graj"

func _on_timeline_changed(value):
	if not is_playing:
		# Scrubbing: set stream_position based on slider (0-100 to 0-8 seconds)
		video_player.stream_position = (value / 100.0) * 8.0

var drag_start_pos = Vector2()
var is_dragging = false

func _input(event):
	if game_over: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if click is inside VideoPlayer
			var rect = video_player.get_global_rect()
			if rect.has_point(event.global_position):
				is_dragging = true
				drag_start_pos = event.global_position
				face_scan_rect.position = drag_start_pos - video_player.global_position
				face_scan_rect.size = Vector2(0, 0)
				face_scan_rect.show()
		else:
			is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		var current_pos = event.global_position
		
		# Clamp to video player bounds
		var rect = video_player.get_global_rect()
		current_pos.x = clamp(current_pos.x, rect.position.x, rect.end.x)
		current_pos.y = clamp(current_pos.y, rect.position.y, rect.end.y)
		
		var top_left = Vector2(min(drag_start_pos.x, current_pos.x), min(drag_start_pos.y, current_pos.y))
		var bottom_right = Vector2(max(drag_start_pos.x, current_pos.x), max(drag_start_pos.y, current_pos.y))
		
		face_scan_rect.position = top_left - video_player.global_position
		face_scan_rect.size = bottom_right - top_left

func _on_motorola_tool_pressed():
	if game_over: return
	
	# Sprawdzamy po pasku postępu (80-100 na suwaku odpowiada końcówce wideo ok. 6.5 - 8 sekundy)
	var is_time_correct = timeline_slider.value >= 80.0
	
	# Sprawdzamy czy narysowano prostokąt w okolicy drzwi A5
	# Wideo ma wymiary od 0,0 do 1240x660 wewnątrz VideoPlayer. 
	# Drzwi A5 i krab są po prawej stronie od środka, lub pośrodku.
	# Ponieważ pozycjonowanie rect w Godot bywa zależne od skalowania,
	# robimy bardzo duży margines błędu.
	var scan_center = face_scan_rect.position + (face_scan_rect.size / 2.0)
	var is_area_correct = false
	if face_scan_rect.visible and face_scan_rect.size.x > 10 and face_scan_rect.size.y > 10:
		# Prawie cała dolna połowa wideo / środek
		# Skoro krab jest u dołu przy drzwiach, zróbmy margines na praktycznie cały środek-dół ekranu
		if scan_center.y > 100: # Wystarczy że nie skanujemy samego nieba!
			is_area_correct = true

	if is_time_correct and is_area_correct:
		is_playing = false
		video_player.paused = true
		play_pause_btn.text = "Graj"
		show_password_prompt()
	elif not is_time_correct:
		# Gracz skanuje za wcześnie
		face_scan_rect.hide()
		show_temporary_warning("Spokojnie, obejrzyj nagranie do końca!")
	else:
		# Penalty for wrong area (time is correct, but area is wrong)
		time_left -= 3.0
		face_scan_rect.hide()
		show_temporary_warning("Skan nieudany! Zaznaczono zły obszar. (-3s)")
		print("Skan nieudany! Czas: ", timeline_slider.value, " Srodek skanu: ", scan_center)

func show_temporary_warning(msg: String):
	var warning_label = Label.new()
	warning_label.text = msg
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 28)
	warning_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	warning_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	$UI.add_child(warning_label)
	
	# Usunięcie po 2 sekundach
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(func():
		warning_label.queue_free()
		timer.queue_free()
	)
	add_child(timer)

func _on_suspect_selected(is_correct: bool):
	database_panel.hide()
	
	if is_correct:
		# Pytanie krzyżowe z optyką
		var overlay = ColorRect.new()
		overlay.color = Color(0, 0, 0, 0.9)
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		
		var label = Label.new()
		label.text = "AUTORYZACJA KOŃCOWA\n\nZidentyfikowano 3 pasujące osoby. Kto z nich był widoczny na nagraniu?\n\n(Podpowiedź: przeanalizuj ich modyfikacje optyczne)"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_right = 1.0
		label.offset_top = 300
		label.add_theme_font_size_override("font_size", 20)
		overlay.add_child(label)
		
		var btn1 = Button.new()
		btn1.text = "Osoba ze wszczepem policzkowym"
		btn1.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 10)
		btn1.position -= Vector2(150, 50)
		btn1.pressed.connect(func(): fail_scene("Błędna identyfikacja!"))
		
		var btn2 = Button.new()
		btn2.text = "Osoba z systemem optycznym 'Czerwone Oczy'"
		btn2.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 10)
		btn2.position -= Vector2(150, -20)
		btn2.pressed.connect(func():
			overlay.queue_free()
			success_scene()
		)
		
		var btn3 = Button.new()
		btn3.text = "Osoba bez widocznych modyfikacji"
		btn3.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 10)
		btn3.position -= Vector2(150, -90)
		btn3.pressed.connect(func(): fail_scene("Błędna identyfikacja!"))
		
		overlay.add_child(btn1)
		overlay.add_child(btn2)
		overlay.add_child(btn3)
		$UI.add_child(overlay)
		
	else:
		fail_scene("Wskazałeś niewłaściwą osobę od razu.")

func success_scene():
	game_over = true
	win_screen.show()
	# Tutaj integracja z GameManager
	# if GameManager: GameManager.story_flags["suspect_identified"] = true
	
	var btn = Button.new()
	btn.text = "Kontynuuj"
	btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 20)
	btn.position.y -= 200
	btn.pressed.connect(func():
		# Przejście do następnej sceny lub powrót do Huba
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	)
	win_screen.add_child(btn)

func fail_scene(reason: String):
	game_over = true
	fail_screen.get_node("Label").text = "Porażka:\n" + reason
	fail_screen.show()
	
	var btn = Button.new()
	btn.text = "Spróbuj ponownie"
	btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 20)
	btn.position.y -= 200
	btn.pressed.connect(func():
		get_tree().reload_current_scene()
	)
	fail_screen.add_child(btn)

func show_tutorial():
	is_playing = false
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "TutorialOverlay"
	
	var label = Label.new()
	label.text = "--- SZKOLENIE OPERATORA ---\n\n1. Przeszukaj nagranie z monitoringu używając suwaka.\n2. Gdy zauważysz Cyberkraba, zatrzymaj wideo i użyj skanera Motorola.\n3. Przyjrzyj się otoczeniu na nagraniu - będziesz potrzebować KODU SEKTORA (widocznego na czerwonych drzwiach)!\n\nMasz 45 sekund."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 24)
	overlay.add_child(label)
	
	var btn = Button.new()
	btn.text = "ROZUMIEM"
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.anchor_top = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -100
	btn.offset_right = 100
	btn.offset_top = -200
	btn.offset_bottom = -150
	btn.pressed.connect(func():
		overlay.queue_free()
		is_playing = true
		play_pause_btn.text = "Pauza"
	)
	overlay.add_child(btn)
	$UI.add_child(overlay)

func show_password_prompt():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -100
	panel.offset_bottom = 100
	overlay.add_child(panel)
	
	var label = Label.new()
	label.text = "AUTORYZACJA MOTOROLA\nPodaj kod sektora widoczny na nagraniu:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.offset_top = 20
	panel.add_child(label)
	
	var input = LineEdit.new()
	input.placeholder_text = "Wpisz kod..."
	input.anchor_left = 0.5
	input.anchor_right = 0.5
	input.offset_left = -100
	input.offset_right = 100
	input.offset_top = 70
	input.offset_bottom = 110
	panel.add_child(input)
	
	var btn = Button.new()
	btn.text = "POTWIERDŹ"
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.offset_left = -75
	btn.offset_right = 75
	btn.offset_top = 130
	btn.offset_bottom = 170
	
	btn.pressed.connect(func():
		if input.text.strip_edges().to_upper() == "A5":
			overlay.queue_free()
			database_panel.show()
		else:
			input.text = ""
			input.placeholder_text = "BŁĘDNY KOD! (-5s)"
			time_left -= 5.0
	)
	panel.add_child(btn)
	$UI.add_child(overlay)
