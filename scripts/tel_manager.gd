extends Control

# --- Ścieżki do węzłów interfejsu ---
@onready var dialer: VBoxContainer = $Dialer
@onready var wyswietlacz_numeru: Label = $Dialer/WyświetlaczNumeru
@onready var klawiatura: GridContainer = $Dialer/Klawiatura
@onready var btn_zadzwon: Button = $Dialer/BtnZadzwon
@onready var opt_random_nb: CheckButton = $Dialer/OptRandomNb

@onready var rozmowa: Control = $Rozmowa
@onready var wybieranie_odpowiedzi: HBoxContainer = $Rozmowa/WybieranieOdpowiedzi
@onready var kolko: Sprite2D = $Rozmowa/Kółko
@onready var text_label: RichTextLabel = $Rozmowa/Text
@onready var btn_rozlacz: Button = $Rozmowa/BtnRozlacz

# --- NOWOŚĆ: Dynamiczny odtwarzacz audio w kodzie ---
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()

# --- NOWOŚĆ: Stałe ścieżki do ogólnych dźwięków telefonu ---
const AUDIO_CALLING = "res://assets/audio/dialing.mp3"       # Dźwięk sygnału oczekiwania (3 sekundy)
const AUDIO_DISCONNECT = "res://assets/audio/rozlacz.mp3" # Dźwięk rozłączenia / zajętości
const AUDIO_ERROR = "res://assets/audio/invalid.mp3"           # Dźwięk "nie ma takiego numeru"

# --- Dane NPC i Numery Telefonów ---
const TARGET_NUMBERS = {
	"glus": "48601247447",
	"lekarz": "126022346"
}

# --- Baza Danych Dialogów (Graf + NOWOŚĆ: Ścieżki Audio) ---
const DIALOGUE_GRAPH = {
	"A": {
		"text": "Halo halo, kto tam? Bartłomiej Głuś przy telefonie.",
		"audio_duration": 3.0,
		"audio": "res://assets/audio/A.mp3",
		"options": ["1", "2", "3"]
	},
	"B": {
		"text": "Tak tak, a ja jestem święty mikołaj. Już panu wierzę.",
		"audio_duration": 4.0,
		"audio": "res://assets/audio/B.mp3",
		"options": ["4", "5"]
	},
	"C": {
		"text": "Świetnie stary! Wreszcie mogę odpocząć od stresu w pracy.",
		"audio_duration": 5.0,
		"audio": "res://assets/audio/C.mp3",
		"options": ["1", "6"]
	},
	"D": {
		"text": "Jejku, ta głupia męcząca Kaśka, co nawet projektora do laptopa nie potrafi podłączyć mogła by się wreszcie uspokoić. Poza tym, jak ona mogła dać komuś mój prywatny numer?",
		"audio_duration": 13.0,
		"audio": "res://assets/audio/D.mp3",
		"options": [],
		"next": "F"
	},
	"E": {
		"text": "Ah, Kaśka i nie tylko. Nie dość że goni mnie z terminami, to nawet moje hobby czyli praca nad moim open-source programem jest nie miła. Co chwile się przypieprza do mnie taki pewien cybercraw37 na Githubie, że odrzucam jego Pull Requesty. A to bot jakiś głupi.",
		"audio_duration": 19.0,
		"audio": "res://assets/audio/E.mp3",
		"options": ["1", "2", "7"]
	},
	"F": {
		"text": "Jestem na urlopie, więc powiem panu: do widzenia. Do pracy wracam za 2 tygodnie.",
		"audio_duration": 7.0,
		"audio": "res://assets/audio/F.mp3",
		"options": [],
		"action": "disconnect"
	},
	"H": {
		"text": "Tak dokładnie! Nawet ostatnio zacząłem szyfrować nagrania, ustawiłem hasło na zaq1. [odgłosy krzyku] Dobra, muszę już kończyć bo moja żona nadepnęła na jeżowca. Pa.",
		"audio_duration": 13.0,
		"audio": "res://assets/audio/H.mp3",
		"options": [],
		"action": "win"
	},
	
	# P-Zdania (Wypowiedzi Gracza / Audio opcjonalne, na razie puste lub ścieżka lektora gracza)
	"1": {
		"text": "Potrzebuję klucza odszyfrowującego monitoring PolyServers.",
		"audio_duration": 3.0,
		"audio": "res://assets/audio/1.mp3",
		"action": "block"
	},
	"2": {
		"text": "Dzień dobry, Krakowska Policja. Jestem śledczym sprawy nr 6721, dotyczącym pożaru biurowca, którego pan podobno jest administratorem. Mam nagrania z monitoringu, potrzebuję hasła aby je odszyfrować.",
		"audio_duration": 11.0,
		"audio": "res://assets/audio/2.mp3",
		"next": "B"
	},
	"3": {
		"text": "Cześć Bartek, jak ci mija urlop?",
		"audio_duration": 2.0,
		"audio": "res://assets/audio/3.mp3",
		"next": "C"
	},
	"4": {
		"text": "Proszę pana, prowadzę poważne śledztwo. Prosimy o współpracę!",
		"audio_duration": 3.0,
		"audio": "res://assets/audio/4.mp3",
		"next": "F"
	},
	"5": {
		"text": "Dostałem numer od Katarzyny Słubickiej. Naprawdę, był w biurowcu pożar. Potrzebujemy tego hasła.",
		"audio_duration": 5.0,
		"audio": "res://assets/audio/5.mp3",
		"next": "D"
	},
	"6": {
		"text": "A co cię tak stresuje?",
		"audio_duration": 1.5,
		"audio": "res://assets/audio/6.mp3",
		"next": "E"
	},
	"7": {
		"text": "A co ty tam robisz w PolyServers dokładnie? Słyszałem, że robisz co ze strukturą budynku, zarządzasz monitoringiem?",
		"audio_duration": 6.0,
		"audio": "res://assets/audio/7.mp3",
		"next": "H"
	}
}

# --- Stan Gry ---
var current_number: String = ""
var is_glus_blocked: bool = false
var is_speaking: bool = false
var pulse_time: float = 0.0
var is_connecting_call: bool = false # Blokada, żeby nie klikać rozłączenia w trakcie dzwonienia

func _ready() -> void:
	add_child(audio_player) # Rejestrujemy odtwarzacz w drzewie
	
	dialer.visible = true
	rozmowa.visible = false
	wyswietlacz_numeru.text = ""
	
	btn_rozlacz.pressed.connect(back_to_dialer)
	
	for button in klawiatura.get_children():
		if button is Button:
			var digit = button.name.replace("Btn", "")
			button.pressed.connect(_on_key_pressed.bind(digit))
			
	btn_zadzwon.pressed.connect(_on_btn_zadzwon_pressed)
	_hide_all_reply_buttons()

func _process(delta: float) -> void:
	if is_speaking:
		pulse_time += delta * 5.0
		var scale_value = 1.0 + sin(pulse_time) * 0.15
		kolko.scale = Vector2(scale_value, scale_value)
	else:
		kolko.scale = Vector2(1.0, 1.0)

# --- Klawiatura Fizyczna ---
func _unhandled_input(event: InputEvent) -> void:
	if dialer.visible and event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_string = OS.get_keycode_string(event.keycode)
		
		if key_string.begins_with("Numpad "):
			key_string = key_string.replace("Numpad ", "")
		
		if key_string.is_valid_int() and key_string.length() == 1:
			_on_key_pressed(key_string)
		elif event.keycode == KEY_BACKSPACE:
			if current_number.length() > 0:
				current_number = current_number.left(current_number.length() - 1)
				_format_display()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_btn_zadzwon_pressed()

func _on_key_pressed(digit: String) -> void:
	if current_number.length() < 12:
		current_number += digit
		_format_display()

func _format_display() -> void:
	if current_number.begins_with("48") and current_number.length() > 2:
		var formatted = "+" + current_number.left(2) + " "
		var rest = current_number.substr(2)
		for i in range(rest.length()):
			if i > 0 and i % 3 == 0:
				formatted += " "
			formatted += rest[i]
		wyswietlacz_numeru.text = formatted
	else:
		wyswietlacz_numeru.text = current_number

# --- Wybieranie numeru i sekwencja dzwonienia ---
func _on_btn_zadzwon_pressed():
	if current_number == "": 
		return
		
	dialer.visible = false
	rozmowa.visible = true
	btn_rozlacz.visible = false
	_hide_all_reply_buttons()
	
	is_connecting_call = true
	text_label.text = "[color=gray][i]Łączenie...[/i][/color]"
	
	# Odtwórz sygnał dzwonienia
	_play_sound(AUDIO_CALLING)
	
	# Czekamy wymuszone 5 sekundy zanim ktoś odbierze lub odrzuci
	await get_tree().create_timer(5.0).timeout
	is_connecting_call = false
	audio_player.stop()
	
	var bypass_block = opt_random_nb.button_pressed
	
	if current_number == TARGET_NUMBERS["glus"]:
		if is_glus_blocked and not bypass_block:
			_play_sound(AUDIO_DISCONNECT)
			_start_fake_call("Sygnał zajętości... Zostałeś zablokowany przez tego użytkownika.")
		else:
			start_dialogue("A")
	elif current_number == TARGET_NUMBERS["lekarz"]:
		_play_sound(AUDIO_ERROR)
		_start_fake_call("Abonent czasowo niedostępny. Spróbuj później. (Funkcja w budowie)")
	else:
		_play_sound(AUDIO_ERROR)
		_start_fake_call("Wybrany numer nie istnieje. Głuchy sygnał w słuchawce...")

func _start_fake_call(message: String):
	text_label.visible_characters = -1
	text_label.text = message
	btn_rozlacz.visible = true

# --- Obsługa Dialogów i Audio Rozmówcy ---
func start_dialogue(node_id: String):
	var node = DIALOGUE_GRAPH[node_id]
	
	_hide_all_reply_buttons()
	btn_rozlacz.visible = false
	
	var prefix = "[b]Bartek:[/b] " if not node_id[0].is_valid_int() else "[b]Ty:[/b] "
	text_label.text = prefix + "[i]\"" + node["text"] + "\"[/i]"
	text_label.visible_characters = 0
	
	# Odtwarzanie dedykowanego pliku głosowego z grafu (jeśli zdefiniowany i istnieje)
	if node.has("audio") and ResourceLoader.exists(node["audio"]):
		_play_sound(node["audio"])
		
	is_speaking = true
	pulse_time = 0.0
	
	var total_chars = text_label.get_total_character_count()
	var tween = create_tween()
	tween.tween_property(text_label, "visible_characters", total_chars, node["audio_duration"])
	
	await tween.finished
	is_speaking = false
	
	if node.has("action"):
		match node["action"]:
			"block":
				is_glus_blocked = true
				_play_sound(AUDIO_DISCONNECT)
				_start_fake_call("\n\n[color=red][b]*Klik!* Połączenie przerwane. Zostałeś zablokowany.[/b][/color]")
				return
			"disconnect":
				_play_sound(AUDIO_DISCONNECT)
				_start_fake_call("\n\n[color=gray][b]*Rozłączono.*[/b][/color]")
				return
			"win":
				_start_fake_call("\n\n[color=green][b]Sukces! Zdobyłeś hasło do monitoringu: zaq1. Śledztwo posunęło się do przodu.[/b][/color]")
				return

	if node.has("next") and node["next"] != "":
		await get_tree().create_timer(1.0).timeout
		start_dialogue(node["next"])
	else:
		_generate_reply_buttons(node["options"])

func _generate_reply_buttons(options: Array):
	var buttons = wybieranie_odpowiedzi.get_children()
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn is Button:
			continue
			
		if btn.pressed.is_connected(start_dialogue):
			btn.pressed.disconnect(start_dialogue)
			
		for connection in btn.pressed.get_connections():
			btn.pressed.disconnect(connection.callable)
		
		if i < options.size():
			var p_node_id = options[i]
			var p_node = DIALOGUE_GRAPH[p_node_id]
			
			btn.text = p_node["text"]
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.visible = true
			
			btn.pressed.connect(func(): start_dialogue(p_node_id))
		else:
			btn.visible = false
			
	btn_rozlacz.visible = true

func _hide_all_reply_buttons():
	for child in wybieranie_odpowiedzi.get_children():
		if child is Button:
			child.visible = false

# --- Pomocnicza funkcja odtwarzania plików ---
func _play_sound(path: String):
	if ResourceLoader.exists(path):
		audio_player.stream = load(path)
		audio_player.play()

func back_to_dialer():
	# Jeśli gracz rozłączy się ręcznie, upewniamy się, że ucinamy dźwięki
	audio_player.stop()
	
	# Jeśli kliknął w trakcie 3 sekund łączenia, nie wywalamy błędów
	is_connecting_call = false 
	
	# Zawsze odtwórz krótkie odłożenie słuchawki przy powrocie
	_play_sound(AUDIO_DISCONNECT)
	
	is_speaking = false
	rozmowa.visible = false
	btn_rozlacz.visible = false
	_hide_all_reply_buttons()
	dialer.visible = true
	current_number = ""
	wyswietlacz_numeru.text = ""
