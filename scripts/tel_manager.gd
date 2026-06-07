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

# --- Dynamiczny odtwarzacz audio w kodzie ---
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var ambient_player: AudioStreamPlayer = AudioStreamPlayer.new()
const AUDIO_BEACH_AMBIENT = "res://assets/audio/plaża.mp3" # Odgłosy morza/plaży
# --- Stałe ścieżki do ogólnych dźwięków telefonu ---
const AUDIO_CALLING = "res://assets/audio/dialing.mp3"       # Dźwięk sygnału oczekiwania (5 sekund)
const AUDIO_DISCONNECT = "res://assets/audio/rozlacz.mp3" # Dźwięk rozłączenia / zajętości
const AUDIO_ERROR = "res://assets/audio/invalid.mp3"           # Dźwięk "nie ma takiego numeru"

# --- Dane NPC i Numery Telefonów ---
const TARGET_NUMBERS = {
	"glus": "48601247447",
	"lekarz": "126022346"
}

# --- Baza Danych Dialogów (Graf + Ścieżki Audio) ---
const DIALOGUE_GRAPH = {
	"A": {
		"text": "Halo halo, kto tam? Bartłomiej Głuś przy telefonie.",
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
	
	# P-Zdania (Wypowiedzi Gracza)
	"1": {
		"text": "Potrzebuję klucza odszyfrowującego monitoring PolyServers.",
		"audio_duration": 3.5,
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
var is_connecting_call: bool = false 

func _ready() -> void:
	add_child(audio_player) 
	add_child(ambient_player)
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
		elif key_string == "Plus" or event.as_text() == "+": # Obsługa fizycznego plusa
			_on_key_pressed("+")
		elif event.keycode == KEY_BACKSPACE:
			if current_number.length() > 0:
				current_number = current_number.left(current_number.length() - 1)
				_format_display()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_btn_zadzwon_pressed()

# --- Logika Dialera (Wprowadzanie Numeru) ---
func _on_key_pressed(digit: String) -> void:
	# Pozwalamy na znak '+' tylko na samym początku wiadomości
	if digit == "+" and current_number.length() > 0:
		return
		
	# Zwiększamy limit znaków do 16, aby zmieścić ewentualny '+' i spacje formatowania
	if current_number.length() < 16:
		current_number += digit
		_format_display()

# --- Dynamiczne i inteligentne formatowanie wyświetlacza ---
func _format_display() -> void:
	var raw = current_number
	var has_plus = raw.begins_with("+")
	
	if has_plus:
		raw = raw.substr(1) # Tymczasowo odcinamy plus do obliczeń
		
	var formatted = "+" if has_plus else ""
	
	# Scenariusz A: Numer zaczyna się od kierunkowego Polski (48)
	if raw.begins_with("48"):
		if raw.length() <= 2:
			formatted += raw
		else:
			formatted += raw.left(2) + " "
			var rest = raw.substr(2)
			for i in range(rest.length()):
				if i > 0 and i % 3 == 0:
					formatted += " "
				formatted += rest[i]
				
	# Scenariusz B: Gracz wpisuje od razu numer komórkowy (np. 601...) lub stacjonarny
	else:
		for i in range(raw.length()):
			if i > 0 and i % 3 == 0:
				formatted += " "
			formatted += raw[i]
			
	wyswietlacz_numeru.text = formatted

# --- Wybieranie numeru z normalizacją wejścia ---
func _on_btn_zadzwon_pressed():
	if current_number == "": 
		return
		
	# --- NORMALIZACJA NUMERU ---
	# Czyścimy numer z plusa, aby uzyskać sam ciąg cyfr do porównania
	var checked_number = current_number
	if checked_number.begins_with("+"):
		checked_number = checked_number.substr(1)
		
	# Jeśli gracz podał sam 9-cyfrowy numer komórkowy Bartka, doklejamy automatycznie kierunkowy '48'
	if checked_number.length() == 9 and checked_number.begins_with("601"):
		checked_number = "48" + checked_number
	# ----------------------------

	dialer.visible = false
	rozmowa.visible = true
	btn_rozlacz.visible = true 
	_hide_all_reply_buttons()
	
	is_connecting_call = true
	text_label.text = "[color=gray][i]Łączenie...[/i][/color]"
	
	_play_sound(AUDIO_CALLING)
	
	await get_tree().create_timer(5.0).timeout
	
	if not rozmowa.visible or not is_connecting_call:
		return
		
	is_connecting_call = false
	audio_player.stop()
	
	var bypass_block = opt_random_nb.button_pressed
	
	# Porównujemy już znormalizowany, czysty ciąg cyfr
	if checked_number == TARGET_NUMBERS["glus"]:
		if is_glus_blocked and not bypass_block:
			_play_sound(AUDIO_DISCONNECT)
			_end_call_by_npc("Sygnał zajętości... Zostałeś zablokowany przez tego użytkownika.")
		else:
			_play_ambient(AUDIO_BEACH_AMBIENT)
			start_dialogue("A")
	elif checked_number == TARGET_NUMBERS["lekarz"]:
		_play_sound(AUDIO_ERROR)
		_end_call_by_npc("Abonent czasowo niedostępny. Spróbuj później. (Funkcja w budowie)")
	else:
		_play_sound(AUDIO_ERROR)
		_end_call_by_npc("Wybrany numer nie istnieje. Głuchy sygnał w słuchawce...")

# --- Logika automatycznego powrotu gdy to NPC kończy połączenie ---
func _end_call_by_npc(message: String):
	ambient_player.stop() # Bartek się rozłącza, więc ucinamy szum morza
	is_speaking = false
	_hide_all_reply_buttons()
	btn_rozlacz.visible = false # Brak przycisku – zostaliśmy rozłączeni przez system/NPC
	
	text_label.visible_characters = -1
	text_label.text = message
	
	# Odczekaj 3 sekundy na przeczytanie komunikatu i automatycznie wyjdź do menu
	await get_tree().create_timer(3.0).timeout
	_clean_ui_to_dialer()

# --- Obsługa Dialogów i Audio Rozmówcy ---
func start_dialogue(node_id: String):
	var node = DIALOGUE_GRAPH[node_id]
	
	_hide_all_reply_buttons()
	btn_rozlacz.visible = true # Podczas rozmowy przycisk działa, dopóki ktoś nie rzuci słuchawką
	
	var prefix = "[b]Bartek:[/b] " if not node_id[0].is_valid_int() else "[b]Ty:[/b] "
	text_label.text = prefix + "[i]\"" + node["text"] + "\"[/i]"
	text_label.visible_characters = 0
	
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
				_end_call_by_npc("\n\n[color=red][b]Połączenie przerwane. Zostałeś zablokowany.[/b][/color]")
				return
			"disconnect":
				_play_sound(AUDIO_DISCONNECT)
				_end_call_by_npc("\n\n[color=gray][b]*Rozłączono.*[/b][/color]")
				return
			"win":
				# Przy wygranej nie puszczamy dźwięku błędu/rozłączenia od razu – dajemy graczowi zapisać hasło
				_end_call_by_npc("\n\n[color=green][b]Sukces! Zdobyłeś hasło do monitoringu: zaq1. Śledztwo posunęło się do przodu.[/b][/color]")
				return

	if node.has("next") and node["next"] != "":
		await get_tree().create_timer(1.0).timeout
		if rozmowa.visible: # Bezpiecznik na wypadek gdyby gracz odłożył słuchawkę w sekundowej przerwie
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

func _play_sound(path: String):
	if ResourceLoader.exists(path):
		audio_player.stream = load(path)
		audio_player.play()

# --- Rozłączenie WYWOŁANE RĘCZNIE przez gracza ---
func back_to_dialer():
	audio_player.stop()
	ambient_player.stop()
	is_connecting_call = false
	
	# Dźwięk odkładania słuchawki generujemy wyłącznie przy ręcznym kliknięciu gracza
	_play_sound(AUDIO_DISCONNECT)
	_clean_ui_to_dialer()

# --- Pomocnicze czyszczenie stanów UI ---
func _clean_ui_to_dialer():
	is_speaking = false
	rozmowa.visible = false
	btn_rozlacz.visible = false
	_hide_all_reply_buttons()
	dialer.visible = true
	current_number = ""
	wyswietlacz_numeru.text = ""

func _play_ambient(path: String):
	if ResourceLoader.exists(path):
		ambient_player.stream = load(path)
		ambient_player.play()
