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
	video_player.texture = normal_texture
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
			
		timeline_slider.value += delta * 15 # Speed of video
		if timeline_slider.value >= 100:
			timeline_slider.value = 0

	update_timer_ui()
	if is_playing:
		update_video_frame()

func update_timer_ui():
	timer_label.text = "Czas: " + str(int(time_left)) + "s"

func update_video_frame():
	if timeline_slider.value >= suspect_start and timeline_slider.value <= suspect_end:
		video_player.texture = suspect_texture
	else:
		video_player.texture = normal_texture

func _on_play_pause_pressed():
	if game_over: return
	is_playing = !is_playing
	play_pause_btn.text = "Pauza" if is_playing else "Graj"

func _on_timeline_changed(value):
	if not is_playing:
		update_video_frame()

func _on_motorola_tool_pressed():
	if game_over: return
	
	if video_player.texture == suspect_texture:
		is_playing = false
		play_pause_btn.text = "Graj"
		face_scan_rect.show()
		show_password_prompt()
	else:
		# Penalty for using tool on wrong frame
		time_left -= 3.0
		# Można dodać dźwięk błędu

func _on_suspect_selected(is_correct: bool):
	database_panel.hide()
	if is_correct:
		success_scene()
	else:
		fail_scene("Wskazałeś niewłaściwą osobę.")

func success_scene():
	game_over = true
	win_screen.show()
	# Tutaj integracja z GameManager
	# if GameManager: GameManager.story_flags["suspect_identified"] = true

func fail_scene(reason: String):
	game_over = true
	fail_screen.get_node("Label").text = "Porażka:\n" + reason
	fail_screen.show()

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
