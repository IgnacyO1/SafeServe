extends "res://scripts/radio.gd"

var gra_aktywna = true
var first_shock_done = false
var camera_shake_amount = 0.0
var player_in_range = false

# Quest States
var quest_wires_completed = false
var quest_breakers_completed = false
var quests_active = false

# Wire Cutting Puzzle State
# Kable sa podlaczone od lewej do prawej - gracz musi je PRZECIAC
var wire_colors = [
	Color(1, 0.15, 0.15),   # Czerwony
	Color(0.2, 0.5, 1),     # Niebieski
	Color(1, 0.85, 0.0),    # Zolty
	Color(0.1, 0.9, 0.3)    # Zielony
]
# wire_cut[i] = true oznacza ze kabel i zostal przeciety
var wire_cut = [false, false, false, false]

# Pozycje kabli w panelu (left endpoint, right endpoint)
# Ustawiane w _ready
var wire_left_pts: Array = []
var wire_right_pts: Array = []

# Breaker Switch State - startuja ON (true), musza byc wylaczone (false)
var breaker_states = [true, true, true, true]
var breaker_buttons: Array = []

# Nazwy obwodow
const BREAKER_NAMES = ["TRAKCJA A", "TRAKCJA B", "STEROWANIE", "AWARYJNE"]

@onready var player = $Gracz
@onready var camera = $Gracz/Camera2D
@onready var prompt_label = $HUD/PromptLabel
@onready var quest_layer = $QuestLayer
@onready var wire_panel = $QuestLayer/QuestPanel/WirePanel
@onready var breaker_container = $QuestLayer/QuestPanel/BreakerPanel/BreakerContainer
@onready var status_label = $QuestLayer/QuestPanel/StatusLabel
@onready var flash_rect = $HUD/FlashRect
@onready var fade_rect = $HUD/FadeRect
@onready var hacked_screen = $HackedScreen
@onready var sparks = $Skrzynka/CPUParticles2D
@onready var hud_rect = $HUD/HUDFadeLayer

func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_6ipol.tscn")
	gra_aktywna = true
	prompt_label.hide()
	quest_layer.hide()
	flash_rect.color.a = 0.0
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 1.0
	hud_rect.hide()
	# Fade in na start
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 1.5)

	# Pozycje kabli wzgledem WirePanel (500x400 Control)
	var start_y = 60.0
	var spacing = 80.0
	for i in range(4):
		wire_left_pts.append(Vector2(30.0, start_y + i * spacing))
		wire_right_pts.append(Vector2(470.0, start_y + i * spacing))

	_setup_breakers_ui()
	_update_quest_status()

	# Podlacz draw i gui_input na wire_panel
	wire_panel.draw.connect(_draw_wires)
	wire_panel.gui_input.connect(_on_wire_panel_gui_input)

func _process(delta: float) -> void:
	# CRT Screen Flickering
	if is_instance_valid(hacked_screen):
		hacked_screen.modulate.a = randf_range(0.72, 1.0)
		if randf() < 0.04:
			hacked_screen.visible = !hacked_screen.visible
		else:
			hacked_screen.visible = true

	# Trigowanie shake
	if camera_shake_amount > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * camera_shake_amount
		camera_shake_amount = move_toward(camera_shake_amount, 0.0, delta * 35.0)
	else:
		camera.offset = Vector2.ZERO

	# Redraw kabli ciagle gdy quest otwarty (dla animacji)
	if quests_active and is_instance_valid(wire_panel):
		wire_panel.queue_redraw()

func _interact_with_skrzynka() -> void:
	if not first_shock_done:
		_trigger_electric_shock()
	else:
		_open_electric_quests()

func _trigger_electric_shock() -> void:
	first_shock_done = true
	gra_aktywna = false
	prompt_label.hide()

	# Dzwiek porazenia
	var sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.stream = load("res://assets/Sounds/bum.mp3")
	sound_player.volume_db = 10.0
	sound_player.play()

	# Wybuch sparkow
	if is_instance_valid(sparks):
		sparks.amount = 120
		sparks.explosiveness = 1.0
		sparks.emitting = true

	# Czerwony flash
	flash_rect.color = Color(1.0, 0.15, 0.1, 0.9)
	var flash_tw = create_tween()
	flash_tw.tween_property(flash_rect, "color:a", 0.0, 0.4)

	# MEGA shake kamery
	camera_shake_amount = 50.0

	# Odrzut gracza na drugi koniec pokoju
	var pushback_target = Vector2(280.0, 570.0)
	await player.apply_shock(pushback_target, 1.1)

	# Reset sparkow
	if is_instance_valid(sparks):
		sparks.amount = 20
		sparks.explosiveness = 0.08

	gra_aktywna = true
	_play_shock_voice()

func _play_shock_voice() -> void:
	# POPRAWKA: Samotny krzyk odtworzony bezpośrednio w grze, bez krótkofalówki i napisów
	var voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	voice_player.stream = load("res://assets/Sounds/dying.mp3")
	voice_player.volume_db = 5.0
	voice_player.play()
	# Usunięcie playera z pamięci po zakończeniu dźwięku
	voice_player.finished.connect(func(): voice_player.queue_free())

func _open_electric_quests() -> void:
	quests_active = true
	gra_aktywna = false
	prompt_label.hide()
	quest_layer.show()
	wire_panel.queue_redraw()

func _close_electric_quests() -> void:
	quests_active = false
	gra_aktywna = true
	quest_layer.hide()

func _on_skrzynka_area_entered(body: Node2D) -> void:
	if body == player:
		player_in_range = true
		if not quests_active:
			prompt_label.text = "[E] Otwórz skrzynkę elektryczną"
			prompt_label.show()

func _on_skrzynka_area_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false
		prompt_label.hide()

# ============================================================
# WIRE CUTTING PUZZLE
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and gra_aktywna and not quests_active:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_interact_with_skrzynka()
				get_viewport().set_input_as_handled()
				return

func _on_wire_panel_gui_input(event: InputEvent) -> void:
	if quest_wires_completed: return
	if not (event is InputEventMouseButton): return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return

	var local_pos = wire_panel.get_local_mouse_position()

	for i in range(4):
		if wire_cut[i]: continue
		var closest = _closest_point_on_segment(local_pos, wire_left_pts[i], wire_right_pts[i])
		if local_pos.distance_to(closest) < 22.0:
			_cut_wire(i)
			wire_panel.accept_event()
			return

func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var t = clamp((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return a + ab * t

func _cut_wire(idx: int) -> void:
	wire_cut[idx] = true
	wire_panel.queue_redraw()

	var snip = AudioStreamPlayer.new()
	add_child(snip)
	snip.stream = load("res://assets/Sounds/cutting.mp3")
	snip.volume_db = 2.0
	snip.play()

	if is_instance_valid(sparks):
		sparks.amount = 40
		sparks.explosiveness = 0.8
		var reset_timer = get_tree().create_timer(0.3)
		await reset_timer.timeout
		if is_instance_valid(sparks):
			sparks.amount = 20
			sparks.explosiveness = 0.08

	_check_quest_completion()

func _draw_wires() -> void:
	for i in range(4):
		var col = wire_colors[i]
		var lp = wire_left_pts[i]
		var rp = wire_right_pts[i]

		if wire_cut[i]:
			var mid = (lp + rp) / 2.0
			var gap = 20.0
			var dead_col = col.darkened(0.5)
			dead_col.a = 0.5
			wire_panel.draw_line(lp, mid - Vector2(gap, 0), dead_col, 10.0, true)
			wire_panel.draw_line(mid + Vector2(gap, 0), rp, dead_col, 10.0, true)
			wire_panel.draw_circle(mid, 8.0, Color(0.8, 0.1, 0.1, 1.0))
		else:
			var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.005 + i * 1.5)
			var bright_col = col.lightened(0.2)
			bright_col.a = pulse
			wire_panel.draw_line(lp, rp, bright_col, 12.0, true)

			wire_panel.draw_circle(lp, 10.0, col)
			wire_panel.draw_circle(rp, 10.0, col)

			wire_panel.draw_string(
				ThemeDB.fallback_font,
				(lp + rp) / 2.0 + Vector2(0, -16),
				"[ KLIKNIJ ABY PRZECIAC ]",
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,
				14,
				Color(1, 1, 1, 0.5)
			)

# ============================================================
# BREAKER PANEL
# ============================================================

func _setup_breakers_ui() -> void:
	for i in range(4):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 70)
		btn.toggle_mode = true
		btn.button_pressed = true
		_style_breaker_button(btn, true)
		btn.toggled.connect(func(state): _on_breaker_toggled(i, state, btn))
		breaker_buttons.append(btn)
		breaker_container.add_child(btn)

func _on_breaker_toggled(index: int, state: bool, btn: Button) -> void:
	breaker_states[index] = state
	_style_breaker_button(btn, state)

	var beep = AudioStreamPlayer.new()
	add_child(beep)
	beep.stream = load("res://assets/Sounds/391650__jeckkech__beep.wav")
	beep.volume_db = -3.0
	beep.play()

	_check_quest_completion()

func _style_breaker_button(btn: Button, is_on: bool) -> void:
	var name_label = BREAKER_NAMES[btn.get_index()] if btn.get_index() < BREAKER_NAMES.size() else "OBWOD"
	btn.text = "%s\n[ %s ]" % [name_label, "ON" if is_on else "OFF"]

	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	style_normal.set_corner_radius_all(8)
	style_hover.set_corner_radius_all(8)

	if is_on:
		style_normal.bg_color = Color("#1c8c30")
		style_hover.bg_color = Color("#22a038")
		btn.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	else:
		style_normal.bg_color = Color("#3a0505")
		style_hover.bg_color = Color("#4d0707")
		btn.add_theme_color_override("font_color", Color(0.6, 0.1, 0.1))

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_font_size_override("font_size", 16)

# ============================================================
# SYSTEM QUESTOW
# ============================================================

func _check_quest_completion() -> void:
	quest_wires_completed = wire_cut.all(func(c): return c == true)
	quest_breakers_completed = breaker_states.all(func(s): return s == false)

	_update_quest_status()

	if quest_wires_completed and quest_breakers_completed:
		_complete_all_quests()

func _update_quest_status() -> void:
	var wires_cut_count = 0
	for c in wire_cut:
		if c: wires_cut_count += 1
	var breakers_off_count = 0
	for s in breaker_states:
		if not s: breakers_off_count += 1

	var status = "STATUS ZASILANIA POCIAGU:\n"
	status += "KABLE: %d/4 PRZECIETE\n" % wires_cut_count
	status += "BEZPIECZNIKI: %d/4 WYLACZONE" % breakers_off_count

	if is_instance_valid(status_label):
		status_label.text = status

func _complete_all_quests() -> void:
	quests_active = false
	quest_layer.hide()

	# NAGŁE zgaśnięcie świateł
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 1.0 
	hud_rect.show()
	prompt_label.hide()

	# NOWOŚĆ: Natychmiastowy dźwięk odcięcia zasilania (power down)
	var power_down_sound = AudioStreamPlayer.new()
	add_child(power_down_sound)
	power_down_sound.stream = load("res://assets/Sounds/hisound-power-outage-451574.mp3") # Możesz zmienić ścieżkę na np. "res://assets/Sounds/power_down.mp3"
	power_down_sound.volume_db = 3.0
	power_down_sound.play()
	power_down_sound.finished.connect(func(): power_down_sound.queue_free())

	# Chwila ciszy/ciemności w napięciu przed komunikatem radiowym (1.5 sekundy)
	await get_tree().create_timer(3.5).timeout

	# Komunikat radiowy
	if is_instance_valid(radio):
		await radio.show_radio_message(
			"Gratulacje! Metro uratowane.",
			"res://assets/Sounds/metro3.mp3"
		)

	get_tree().change_scene_to_file("res://scenes/multiplayer_wybór.tscn")

func _on_close_button_pressed() -> void:
	_close_electric_quests()
