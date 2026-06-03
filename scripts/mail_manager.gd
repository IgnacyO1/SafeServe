extends Control

# Referencje do węzłów UI z Twojego drzewa sceny
@onready var kontakty_vbox = $KontaktyPanel/KontaktyScroll/KontaktyVBox
@onready var maile_vbox = $MailePanel/MaileScroll/MaileVBox
@onready var tresci_label = $TreśćPanel/TreśćMaila
@onready var wybieranie_odbiorcy = $NowaWiadomość/WybieranieOdbiorcy
@onready var opcja_panel = $NowaWiadomość/NowaWiadomośćPanel

# Bezpośrednie referencje do stałych przycisków opcji i wysyłania
@onready var opcja_btn_1 = $NowaWiadomość/NowaWiadomośćPanel/OpcjaBtn1
@onready var opcja_btn_2 = $NowaWiadomość/NowaWiadomośćPanel/OpcjaBtn2
@onready var opcja_btn_3 = $NowaWiadomość/NowaWiadomośćPanel/OpcjaBtn3
@onready var wyslij_btn = $"NowaWiadomość/Wyślij Btn" # Uwzględniona spacja w nazwie węzła

# --- SZTYWNE DANE DRZEWA DIALOGOWEGO (Zamiast śmieciowych JSONów) ---
var contacts_data = {
	"boss": {
		"name": "Mateusz Puławski",
		"title": "Komisarz Policji w Krakowie",
		"email": "m.pulawski@kp.krakow.pl"
	},
	"katarzyna": {
		"name": "Katarzyna Słubicka",
		"title": "CEO PolyServers",
		"email": "k.slubicka@polyservers.com"
	}
}

var dialogue_tree = {
	"katarzyna": {
		"pozary": {
			"button_text": "Okoliczności pożaru",
			"player_mail": "Dzień dobry. Prowadzimy analizę zdarzeń związanych z pożarem Państwa biurowca. Czy posiada Pani informacje, które mogłyby pomóc ustalić przyczynę zdarzenia?\n\nGreg, śledczy sprawy nr 6721",
			"reply_subject": "Odpowiedź: Okoliczności pożaru",
			"reply_text": "Dzień dobry. Niestety nie wiem nic ponad to, co przekazały służby. To był tragiczny dzień dla całej firmy. Straciliśmy część infrastruktury, chociaż przynajmniej mieliśmy kopie zapasowe. Nadal próbujemy oszacować skalę strat.\n\nKatarzyna Słubicka, CEO PolyServers",
			"unlocks": "lokalizacja"
		},
		"lokalizacja": {
			"button_text": "Pytaj o lokalizację",
			"player_mail": "Czy pani była w Krakowie gdy to się działo?\n\nGreg, śledczy sprawy nr 6721",
			"reply_subject": "Odpowiedź: Lokalizacja",
			"reply_text": "Nie, ja rzadko jestem w biurze. Byłam wtedy podczas podróży służbowej na Tajwan, na konferencji związanej z AI.\n\nKatarzyna Słubicka, CEO PolyServers",
			"unlocks": "podejrzane"
		},
		"podejrzane": {
			"button_text": "Pytaj o podejrzane zachowania",
			"player_mail": "Czy w firmie ostatnio działo się coś podejrzanego?\n\nGreg, śledczy sprawy nr 6721",
			"reply_subject": "Ostatni raz odpowiadam",
			"reply_text": "Powtarzałam już panu, że nic dziwnego nie obserwowałam!!! Już więcej panu odpowiadać nie będę, nie mam na to czasu, bo widzę że jest pan niepoważny.\n\nKatarzyna Słubicka, CEO PolyServers",
			"unlocks": ""
		},
		"monitoring": {
			"button_text": "Monitoring budynku",
			"player_mail": "Dzień dobry. Czy posiada Pani dostęp do nagrań monitoringu z dnia pożaru?\n\nGreg, śledczy sprawy nr 6721",
			"reply_subject": "Odpowiedź: Monitoring",
			"reply_text": "Nie. System monitoringu jest zarządzany przez administratora budynku. Ja nie mam uprawnień do odszyfrowywania ani eksportowania nagrań.\n\nCEO PolyServers",
			"unlocks": "uprawnienia"
		},
		"uprawnienia": {
			"button_text": "Kto ma uprawnienia?",
			"player_mail": "A kto w firmie ma takie uprawnienia?\n\nGreg, śledczy sprawy nr 6721",
			"reply_subject": "Odpowiedź: Uprawnienia",
			"reply_text": "Administratorem jest Bartłomiej Głuś. Obecnie przebywa na urlopie poza krajem. Nie odpowiada ostatnio na maile, ale w tej sytuacji mogę przekazać jego prywatny numer telefonu:\n\n+48 601 247 447\n\nProszę powołać się na mnie podczas kontaktu.\n\nKatarzyna Słubicka, CEO PolyServers",
			"unlocks": ""
		},
		"administrator": {
			"button_text": "Administrator budynku",
			"player_mail": "Dzień dobry. Kto odpowiada za systemy techniczne budynku?\n\nGreg, śledczy sprawy nr 6721",
			"reply_subject": "Odpowiedź: Administrator",
			"reply_text": "Administratorem jest Bartłomiej Głuś. Obecnie przebywa na urlopie poza krajem. Nie odpowiada ostatnio na maile, ale w tej sytuacji mogę przekazać jego prywatny numer telefonu:\n\n+48 601 247 447\n\nProszę powołać się na mnie podczas kontaktu.\n\nKatarzyna Słubicka, CEO PolyServers",
			"unlocks": ""
		}
	}
}

# Stan Gry
var received_mails: Array = []
var active_recipient_id: String = ""
var selected_option_key: String = ""
# Pula aktualnie dostępnych dla gracza tematów (zmienia się wraz z postępem śledztwa)
var katarzyna_pool: Array = ["pozary", "monitoring", "administrator"]

func _ready() -> void:
	_setup_initial_state()
	_create_contact_buttons()
	_connect_ui_signals()
	_refresh_mail_list()

func _setup_initial_state() -> void:
	# Mail startowy od Szefa (Screen 2)
	received_mails.append({
		"from_id": "boss",
		"from_name": "Mateusz Puławski",
		"subject": "Zerknij na to.",
		"content": "Daliśmy ci dostęp do centrum inwestygacyjnego, możesz tutaj się kontaktować ze świadkami. Dostaliśmy też kontakty do Polyservers, przepytaj ludzi i znajdź jaka była przyczyna tego piekielnego pożaru. Chciałbym zamknąć śledztwo w przyszłym tygodniu, bo mamy mnóstwo papierkologii.\n\nMateusz Puławski, Komisarz Policji w Krakowie"
	})
	opcja_panel.visible = false
	tresci_label.text = "Wybierz mail z listy lub kontakt z lewej strony, aby rozpocząć interakcję."

func _connect_ui_signals() -> void:
	# Podpięcie stałych przycisków wyboru tematów
	opcja_btn_1.pressed.connect(_on_option_selected.bind(1))
	opcja_btn_2.pressed.connect(_on_option_selected.bind(2))
	opcja_btn_3.pressed.connect(_on_option_selected.bind(3))
	wyslij_btn.pressed.connect(_on_send_pressed)

func _create_contact_buttons() -> void:
	for child in kontakty_vbox.get_children():
		child.queue_free()
		
	for key in contacts_data.keys():
		var contact = contacts_data[key]
		var btn = Button.new()
		btn.text = contact["name"]
		btn.custom_minimum_size = Vector2(250, 50)
		btn.pressed.connect(_on_contact_clicked.bind(key))
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
	# Wyłącza panel pisania nowej wiadomości podczas czytania skrzynki odbiorczej
	opcja_panel.visible = false
	wybieranie_odbiorcy.visible = false
	
	tresci_label.clear()
	tresci_label.append_text("[b]Od:[/b] %s\n" % mail["from_name"])
	tresci_label.append_text("[b]Temat:[/b] %s\n" % mail["subject"])
	tresci_label.append_text("---------------------------------------------\n\n")
	tresci_label.append_text(mail["content"])

func _on_contact_clicked(contact_id: String) -> void:
	active_recipient_id = contact_id
	selected_option_key = ""
	wyslij_btn.disabled = true
	
	var contact = contacts_data[contact_id]
	wybierancy_odbiorcy_update(contact["name"])
	
	if contact_id == "boss":
		tresci_label.text = "Komisarz Puławski nie przyjmuje pytań. Czeka na raport końcowy z Twojego śledztwa."
		opcja_panel.visible = false
		return
		
	_update_writing_options()

func wybierancy_odbiorcy_update(name_text: String) -> void:
	wybieranie_odbiorcy.visible = true
	if wybieranie_odbiorcy is Label:
		wybieranie_odbiorcy.text = "Do: " + name_text
	elif wybieranie_odbiorcy is OptionButton:
		wybieranie_odbiorcy.clear()
		wybieranie_odbiorcy.add_item(name_text)

func _update_writing_options() -> void:
	opcja_panel.visible = true
	
	# Ukrywamy na start wszystkie przyciski
	opcja_btn_1.visible = false
	opcja_btn_2.visible = false
	opcja_btn_3.visible = false
	
	# Pobierz pulę opcji dla wybranej osoby
	var current_pool = katarzyna_pool
	var available_count = current_pool.size()
	
	if available_count == 0:
		tresci_label.text = "Brak nowych tematów do rozmowy z tym świadkiem."
		opcja_panel.visible = false
		return
		
	tresci_label.text = "Wybierz temat wiadomości, którą chcesz sformułować i wysłać:"
	
	# Przypisujemy teksty do przycisków w zależności od tego ile ich zostało w puli
	if available_count >= 1:
		var opt1 = dialogue_tree["katarzyna"][current_pool[0]]
		opcja_btn_1.text = opt1["button_text"]
		opcja_btn_1.visible = true
		opcja_btn_1.set_meta("option_key", current_pool[0])
		
	if available_count >= 2:
		var opt2 = dialogue_tree["katarzyna"][current_pool[1]]
		opcja_btn_2.text = opt2["button_text"]
		opcja_btn_2.visible = true
		opcja_btn_2.set_meta("option_key", current_pool[1])
		
	if available_count >= 3:
		var opt3 = dialogue_tree["katarzyna"][current_pool[2]]
		opcja_btn_3.text = opt3["button_text"]
		opcja_btn_3.visible = true
		opcja_btn_3.set_meta("option_key", current_pool[2])

func _on_option_selected(btn_index: int) -> void:
	var target_btn: Button
	match btn_index:
		1: target_btn = opcja_btn_1
		2: target_btn = opcja_btn_2
		3: target_btn = opcja_btn_3
		
	if target_btn and target_btn.has_meta("option_key"):
		selected_option_key = target_btn.get_meta("option_key")
		var node_data = dialogue_tree[active_recipient_id][selected_option_key]
		
		# Podgląd maila w głównym oknie przed wysłaniem
		tresci_label.clear()
		tresci_label.append_text("[b]Podgląd wiadomości do wysłania:[/b]\n\n")
		tresci_label.append_text(node_data["player_mail"])
		
		wyslij_btn.disabled = false

func _on_send_pressed() -> void:
	if selected_option_key == "" or active_recipient_id == "":
		return
		
	var node_data = dialogue_tree[active_recipient_id][selected_option_key]
	
	# Zablokuj UI na czas "wysyłania i oczekiwania"
	wyslij_btn.disabled = true
	opcja_panel.visible = false
	tresci_label.text = "Wysyłanie wiadomości...\nCzekam na odpowiedź od: %s..." % contacts_data[active_recipient_id]["name"]
	
	# Usunięcie zużytej opcji z puli aktywnego wyboru (żeby gracz nie pytał o to samo)
	katarzyna_pool.erase(selected_option_key)
	
	# Symulacja czasu dostarczenia maila (np. 2 sekundy zamiast nudnych 10)
	await get_tree().create_timer(2.0).timeout
	
	# Generowanie odpowiedzi od NPC i dodanie jej do skrzynki odbiorczej
	var incoming_mail = {
		"from_id": active_recipient_id,
		"from_name": contacts_data[active_recipient_id]["name"],
		"subject": node_data["reply_subject"],
		"content": node_data["reply_text"]
	}
	received_mails.append(incoming_mail)
	
	# Odblokowanie nowej gałęzi w drzewie (jeśli istnieje)
	if node_data["unlocks"] != "" and not katarzyna_pool.has(node_data["unlocks"]):
		katarzyna_pool.append(node_data["unlocks"])
		
	# Odświeżenie widoku skrzynki mailowej
	_refresh_mail_list()
	
	# Automatyczne wyświetlenie nowo otrzymanej wiadomości w oknie głównym
	_on_mail_clicked(incoming_mail)
