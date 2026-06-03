extends Control

# Referencje do węzłów UI
@onready var kontakty_vbox = $KontaktyPanel/KontaktyScroll/KontaktyVBox
@onready var maile_vbox = $MailePanel/MaileScroll/MaileVBox
@onready var tresci_label = $TreśćPanel/TreśćMaila
@onready var tresci_panel = $TreśćPanel
@onready var opcja_panel = $NowaWiadomość/NowaWiadomośćPanel

# Bezpośrednie referencje do stałych przycisków opcji
@onready var opcja_btn_1 = $NowaWiadomość/NowaWiadomośćPanel/OpcjaBtn1
@onready var opcja_btn_2 = $NowaWiadomość/NowaWiadomośćPanel/OpcjaBtn2
@onready var opcja_btn_3 = $NowaWiadomość/NowaWiadomośćPanel/OpcjaBtn3
@onready var wyslij_btn = $"NowaWiadomość/Wyślij Btn"

# --- DRZEWO DIALOGOWE KATARZYNA SŁUBICKA ---
var dialogue_tree = {
	"katarzyna": {
		"initial_fire": {
			"subject": "Okoliczności pożaru",
			"content": "Dzień dobry. Prowadzimy analizę zdarzeń związanych z pożarem Państwa biurowca. Czy posiada Pani informacje, które mogłyby pomóc ustalić przyczynę zdarzenia?\n\nGreg, śledczy sprawy nr 6721",
			"from": "Greg",
			"can_reply": true,
			"reply_options": ["monitoring", "administrator", "lokalizacja"]  # 3 pytania dostępne po tym mailu
		},
		"monitoring": {
			"button_text": "Monitoring budynku",
			"player_mail": "Czy posiada Pani dostęp do nagrań monitoringu z dnia pożaru?",
			"npc_reply": {
				"subject": "RE: Monitoring budynku",
				"content": "Nie. System monitoringu jest zarządzany przez administratora budynku. Ja nie mam uprawnień do odszyfrowywania ani eksportowania nagrań.\n\nKatarzyna Słubicka, CEO PolyServers"
			},
			"unlocks": ["pytanie_uprawnienia"]
		},
		"pytanie_uprawnienia": {
			"button_text": "Kto ma uprawnienia?",
			"player_mail": "A kto w firmie ma takie uprawnienia?",
			"npc_reply": {
				"subject": "RE: Uprawnienia",
				"content": "Administratorem jest Bartłomiej Głuś. Obecnie przebywa na urlopie poza krajem. Nie odpowiada ostatnio na maile, ale w tej sytuacji mogę przekazać jego prywatny numer telefonu:\n\n+48 601 247 447\n\nProszę powołać się na mnie podczas kontaktu.\n\nKatarzyna Słubicka, CEO PolyServers"
			},
			"unlocks": []
		},
		"administrator": {
			"button_text": "Administrator budynku",
			"player_mail": "Kto odpowiada za systemy techniczne budynku?",
			"npc_reply": {
				"subject": "RE: Administrator",
				"content": "Administratorem jest Bartłomiej Głuś. Obecnie przebywa na urlopie poza krajem. Nie odpowiada ostatnio na maile, ale w tej sytuacji mogę przekazać jego prywatny numer telefonu:\n\n+48 601 247 447\n\nProszę powołać się na mnie podczas kontaktu.\n\nKatarzyna Słubicka, CEO PolyServers"
			},
			"unlocks": []
		},
		"lokalizacja": {
			"button_text": "Lokalizacja",
			"player_mail": "Czy pani była w Krakowie gdy to się działo?",
			"npc_reply": {
				"subject": "RE: Lokalizacja",
				"content": "Nie, ja rzadko jestem w biurze. Byłam wtedy podczas podróży służbowej na Tajwan, na konferencji związanej z AI.\n\nKatarzyna Słubicka, CEO PolyServers"
			},
			"unlocks": ["pytanie_podejrzane"]
		},
		"pytanie_podejrzane": {
			"button_text": "Czy działo się coś podejrzanego?",
			"player_mail": "Czy w firmie ostatnio działo się coś podejrzanego?",
			"npc_reply": {
				"subject": "Ostatni raz odpowiadam",
				"content": "Powtarzałam już panu, że nic dziwnego nie obserwowałam!!!! Już więcej panu odpowiadać nie będę, nie mam na to czasu, bo widzę że jest pan niepoważny.\n\nKatarzyna Słubicka, CEO PolyServers"
			},
			"unlocks": []
		}
	}
}

# Stan gry
var received_mails: Array = []
var current_viewed_mail: Dictionary = {}
var active_recipient: String = ""
var selected_option_key: String = ""
var katarzyna_available_options: Array = []  # Opcje dostępne dla Katarzyny
var waiting_for_reply: bool = false

func _ready() -> void:
	_setup_initial_state()
	_create_contact_buttons()
	_connect_ui_signals()
	_refresh_mail_list()

func _setup_initial_state() -> void:
	# Mail initial od Grega - to jest pierwszy mail w grze
	var initial_mail = {
		"id": "initial_fire",
		"from": "Greg",
		"from_name": "Greg, śledczy sprawy nr 6721",
		"subject": dialogue_tree["katarzyna"]["initial_fire"]["subject"],
		"content": dialogue_tree["katarzyna"]["initial_fire"]["content"],
		"can_reply": true,
		"recipient": "katarzyna",
		"node_key": "initial_fire"
	}
	received_mails.append(initial_mail)
	
	# Na starcie dostępne są 3 opcje odpowiedzi
	katarzyna_available_options = dialogue_tree["katarzyna"]["initial_fire"]["reply_options"]
	
	opcja_panel.visible = false
	tresci_label.text = "Wybierz mail, aby go przeczytać. Jeśli możesz odpowiedzieć, pojawi się przycisk 'Odpowiedz'."

func _connect_ui_signals() -> void:
	opcja_btn_1.pressed.connect(_on_option_selected.bind(1))
	opcja_btn_2.pressed.connect(_on_option_selected.bind(2))
	opcja_btn_3.pressed.connect(_on_option_selected.bind(3))
	wyslij_btn.pressed.connect(_on_send_pressed)

func _create_contact_buttons() -> void:
	for child in kontakty_vbox.get_children():
		child.queue_free()
	
	# Tylko Katarzyna jest dostępna
	var btn = Button.new()
	btn.text = "Katarzyna Słubicka"
	btn.custom_minimum_size = Vector2(250, 50)
	btn.pressed.connect(_on_contact_clicked.bind("katarzyna"))
	kontakty_vbox.add_child(btn)

func _refresh_mail_list() -> void:
	for child in maile_vbox.get_children():
		child.queue_free()
	
	for mail in received_mails:
		var btn = Button.new()
		btn.text = "[%s] %s" % [mail["from_name"], mail["subject"]]
		btn.custom_minimum_size = Vector2(300, 45)
		btn.pressed.connect(_on_mail_clicked.bind(mail))
		maile_vbox.add_child(btn)

# --- OBSŁUGA KLIKNIĘĆ ---

func _on_mail_clicked(mail: Dictionary) -> void:
	current_viewed_mail = mail
	wyslij_btn.visible = false
	
	# Wyświetl zawartość maila
	tresci_label.clear()
	tresci_label.append_text("[b]Od:[/b] %s\n" % mail["from_name"])
	tresci_label.append_text("[b]Temat:[/b] %s\n" % mail["subject"])
	tresci_label.append_text("---------------------------------------------\n\n")
	tresci_label.append_text(mail["content"])
	
	# Jeśli mail można odpowiedzieć, pokaż przycisk "Odpowiedz" w opcja_panel
	if mail.get("can_reply", false):
		opcja_panel.visible = true
		opcja_btn_1.visible = true
		opcja_btn_1.text = "Odpowiedz"
		opcja_btn_1.set_meta("is_reply_button", true)
		opcja_btn_2.visible = false
		opcja_btn_3.visible = false
	else:
		opcja_panel.visible = false

func _show_reply_button() -> void:
	# Funkcja więcej nie potrzebna - logika przeniesiona do _on_mail_clicked
	pass

func _on_reply_clicked() -> void:
	# Pokaż opcje odpowiedzi
	active_recipient = current_viewed_mail.get("recipient", "katarzyna")
	selected_option_key = ""
	wyslij_btn.visible = true
	wyslij_btn.disabled = true
	
	# Tekst w panelu treści powinien być minimalny - opcje są na przyciskach
	tresci_label.clear()
	tresci_label.append_text("[b]Wybierz temat wiadomości:[/b]")
	
	# Ukryj wszystkie przyciski opcji
	opcja_btn_1.visible = false
	opcja_btn_2.visible = false
	opcja_btn_3.visible = false
	
	# Pobierz dostępne opcje
	var available_count = katarzyna_available_options.size()
	if available_count == 0:
		tresci_label.append_text("\n\nBrak dostępnych opcji.")
		opcja_panel.visible = false
		return
	
	# Przypisz opcje do przycisków - tekst będzie bezpośrednio na przyciskach
	if available_count >= 1:
		var option_key = katarzyna_available_options[0]
		var option_data = dialogue_tree[active_recipient][option_key]
		opcja_btn_1.text = option_data["button_text"]
		opcja_btn_1.visible = true
		opcja_btn_1.set_meta("option_key", option_key)
		opcja_btn_1.remove_meta("is_reply_button")
	
	if available_count >= 2:
		var option_key = katarzyna_available_options[1]
		var option_data = dialogue_tree[active_recipient][option_key]
		opcja_btn_2.text = option_data["button_text"]
		opcja_btn_2.visible = true
		opcja_btn_2.set_meta("option_key", option_key)
	
	if available_count >= 3:
		var option_key = katarzyna_available_options[2]
		var option_data = dialogue_tree[active_recipient][option_key]
		opcja_btn_3.text = option_data["button_text"]
		opcja_btn_3.visible = true
		opcja_btn_3.set_meta("option_key", option_key)

func _on_option_selected(btn_index: int) -> void:
	var target_btn: Button
	match btn_index:
		1: target_btn = opcja_btn_1
		2: target_btn = opcja_btn_2
		3: target_btn = opcja_btn_3
	
	# Jeśli to przycisk "Odpowiedz", obsłuż inaczej
	if target_btn and target_btn.has_meta("is_reply_button"):
		_on_reply_clicked()
		return
	
	# Normalna obsługa wyboru opcji
	if target_btn and target_btn.has_meta("option_key"):
		selected_option_key = target_btn.get_meta("option_key")
		wyslij_btn.disabled = false

func _on_contact_clicked(contact_id: String) -> void:
	pass  # Nie trzeba, bo interakcje odbywają się przez maile

func _on_send_pressed() -> void:
	if selected_option_key == "" or waiting_for_reply:
		return
	
	waiting_for_reply = true
	wyslij_btn.disabled = true
	opcja_panel.visible = false
	
	var option_data = dialogue_tree[active_recipient][selected_option_key]
	
	# Pokaż wiadomość czekania
	tresci_label.clear()
	tresci_label.append_text("[b]Wysyłanie wiadomości...[/b]\n\n")
	tresci_label.append_text(option_data["player_mail"])
	tresci_label.append_text("\n\n[i]Czekam na odpowiedź od Katarzyny (10 sekund)...[/i]")
	
	# Czekaj 10 sekund
	await get_tree().create_timer(10.0).timeout
	
	# Usuń opcję z dostępnych (aby gracz nie wysyłał tego samego pytania)
	katarzyna_available_options.erase(selected_option_key)
	
	# Dodaj nowe odblokowane opcje
	for unlocked in option_data["unlocks"]:
		if not katarzyna_available_options.has(unlocked):
			katarzyna_available_options.append(unlocked)
	
	# Utwórz mail z odpowiedzią NPC
	var npc_reply = {
		"id": selected_option_key + "_reply",
		"from": "Katarzyna",
		"from_name": "Katarzyna Słubicka, CEO PolyServers",
		"subject": option_data["npc_reply"]["subject"],
		"content": option_data["npc_reply"]["content"],
		"can_reply": katarzyna_available_options.size() > 0,
		"recipient": "katarzyna",
		"node_key": selected_option_key
	}
	received_mails.append(npc_reply)
	
	# Odśwież listę maili i wyświetl odpowiedź
	_refresh_mail_list()
	_on_mail_clicked(npc_reply)
	
	waiting_for_reply = false
	selected_option_key = ""
	wyslij_btn.disabled = true
