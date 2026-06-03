extends Control

# --- Ścieżki do węzłów interfejsu ---
@onready var kontakty_vbox = $KontaktyPanel/KontaktyScroll/KontaktyVBox
@onready var maile_vbox = $MailePanel/MaileScroll/MaileVBox
@onready var tresc_maila = $TreśćPanel/TreśćMaila
@onready var btn_odpowiedz = $BtnOdpowiedz

@onready var wybieranie_odbiorcy = $NowaWiadomość/WybieranieOdbiorcy
@onready var nowa_wiadomosc_panel = $NowaWiadomość/NowaWiadomośćPanel
@onready var wyslij_btn = $"NowaWiadomość/Wyślij Btn"

# --- Baza Danych Grafu Mailowego ---
const CONTACTS = {
	"pulaski": {"name": "Mateusz Puławski", "email": "komisarz.pulaski@policja.krakow.pl"},
	"maslo": {"name": "Robert Masło", "email": "robert.maslo@straz.krakow.pl"},
	"slubicka": {"name": "Katarzyna Słubicka", "email": "ceo@polyservers.com"},
	"glus": {"name": "Bartłomiej Głuś", "email": "bglus@polyservers.com"},
	"rumian": {"name": "Radosław Rumian", "email": "rrumian@polyservers.com"},
	"pingwin": {"name": "Marta Pingwin", "email": "mpingwin@polyservers.com"}
}

# --- Ścieżki do awatarów kontaktów ---
const AVATARS = {
	"pulaski": "res://assets/graphics/Scena4/mateusz_pułaski.png",
	"maslo": "res://assets/graphics/Scena4/robert_maslo.png",
	"slubicka": "res://assets/graphics/Scena4/katarzyna_słubicka.png",
	"glus":  "res://assets/graphics/Scena4/robert_maslo.png",
	"rumian":  "res://assets/graphics/Scena4/radek_rumian.png",
	"pingwin":  "res://assets/graphics/Scena4/marta_pingwin.png",
	"default":  "res://assets/graphics/Scena4/awaria.jpeg" # Awatar awaryjny
}

const AVATAR_SIZE = Vector2(32, 32) # Rozmiar kółka awatara w pikselach

const EMAILS = {
	# NPC Maile (Litery)
	"A": {"sender": "pulaski", "subject": "Zerknij na to.", "body": "Daliśmy ci dostęp do centrum inwestygacyjnego, możesz tutaj się kontaktować ze świadkami. Dostaliśmy też kontakty do Polyservers, przepytaj ludzi i znajdź jaka była przyczyna tego piekielnego pożaru. Chciałbym zamknąć śledztwo w przyszłym tygodniu, bo mamy mnóstwo papierkologii.\n\nMateusz Puławski, Komisarz Policji w Krakowie"},
	"B": {"sender": "maslo", "subject": "Pożar", "body": "Cześć Greg,\nByłem razem z tobą wtedy gasić pożar. Wiem, że był twój pierwszy dzień, mam nadzieję że sobie poradziłeś tam na dole.\nJako ekspert w gaszeniu pożaru z 20 letnim doświadczeniem, powiem ci że ten pożar był dziwny. Zaczął się w serwerowni, ale ominął zabezpieczenia przeciwpożarowe i rozprzestrzenił się na cały budynek. Dziwna sprawa.\n\nPozdrawiam, trzymaj się dobrze,\nRobert Masło"},
	"C": {"sender": "slubicka", "subject": "Odpowiedź", "body": "Dzień dobry. Niestety nie wiem nic ponad to, co przekazały służby. To był tragiczny dzień dla całej firmy. Straciliśmy część infrastruktury, chociaż przynajmniej mieliśmy kopie zapasowe. Nadal próbujemy oszacować skalę strat.\n\nKatarzyna Słubicka\nCEO PolyServers"},
	"D": {"sender": "slubicka", "subject": "Odpowiedź", "body": "Nie. System monitoringu jest zarządzany przez administratora budynku. Ja nie mam uprawnień do odszyfrowywania ani eksportowania nagrań.\n\nCEO PolyServers"},
	"E": {"sender": "slubicka", "subject": "Bartek", "body": "Administratorem jest Bartłomiej Głuś. Obecnie przebywa na urlopie poza krajem. Nie odpowiada ostatnio na maile, ale w tej sytuacji mogę przekazać jego prywatny numer telefonu:\n\n+48 601 247 447\n\nProszę powołać się na mnie podczas kontaktu telefonicznego.\n\nKatarzyna Słubicka, CEO PolyServers"},
	"F": {"sender": "slubicka", "subject": "Nie", "body": "Nie, ja rzadko jestem w biurze. Byłam wtedy podczas podróży służbowej na Tajwan, na konferencji związanej z AI.\n\nKatarzyna Słubicka,\nCEO PolyServers"},
	"G": {"sender": "slubicka", "subject": "Ostatni raz odpowiadam", "body": "Powtarzałam już panu, że nic dziwnego nie obserwowałam!!!! Już więcej panu odpowiadać nie będę, nie mam na to czasu, bo widzę że jest pan niepoważny.\n\nKatarzyna Słubicka,\nCEO PolyServers"},
	"H": {"sender": "rumian", "subject": "Re: Przebieg zdarzeń", "body": "Około pięciu minut przed alarmem byłem w toalecie. Kiedy wróciłem, uruchomiono procedurę ewakuacji. Zająłem się wyprowadzaniem pracowników z budynku."},
	"I": {"sender": "rumian", "subject": "Re: Monitoring", "body": "Nie zajmuję się monitoringiem. Od tego jest administrator budynku. Moim zadaniem była ochrona fizyczna obiektu."},
	"J": {"sender": "rumian", "subject": "Re: Zabezpieczenia", "body": "Tak. Elektroniczne zamki zostały dostarczone przez firmę Niezawodna Ochrona Nowy Sącz S.A. Już w pierwszym tygodniu po instalacji Marta z działu DevOpsów znalazła w nich poważną lukę bezpieczeństwa.\nProducent ignorował nasze zgłoszenia. Nie mieliśmy środków na wymianę systemu.\nIronia losu jest taka, że w przyszłym tygodniu mieliśmy rozpocząć wdrażanie nowego systemu bezpieczeństwa od Motorola Solutions."},
	"K": {"sender": "rumian", "subject": "Koniec ustaleń", "body": "To wszystko co mogę panu powiedzieć. Życzę powodzenia w śledztwie. Ja jestem tylko ochroniarzem, którego rola jest obserwująco-dekoracyjna"},
	"L": {"sender": "pingwin", "subject": "Re: Pożar", "body": "Wszystko wydarzyło się bardzo szybko. Przez chwilę myślałam, że nie uda mi się wydostać z budynku. Nigdy wcześniej nie przeżyłam czegoś podobnego.\n\nMarta Pingwin, Head of Consistent Operations PolyServers"},
	"M": {"sender": "pingwin", "subject": "Re: System Zamków", "body": "Tak. Podczas testów odkryłam ukryty mechanizm pozwalający ominąć część zabezpieczeń. Zgłosiłam to przełożonym, ale producent nie potraktował sprawy poważnie.\n\nMarta Pingwin, Head of Consistent Operations PolyServers"},
	"N": {"sender": "pingwin", "subject": "Re: Nietypowe Zdarzenia", "body": "Właściwie tak.\nKilka minut przed alarmem słyszałam dziwny metaliczny stukot dochodzący z kanałów wentylacyjnych nad serwerownią.\nUznałam wtedy, że to jakaś ekipa techniczna albo serwis. Teraz nie jestem już tego taka pewna. \n\nMarta Pingwin, Head of Consistent Operations PolyServers"},
	"SUGESTIA_BARTEK": {"sender": "glus", "subject": "Automatyczna odpowiedź / Sugestia", "body": "*Bartłomiej Głuś jest na urlopie, spróbuj innej metody kontaktu (np. telefonicznie, jeśli zdobędziesz numer)*"},

	# Player Maile (Liczby)
	"1": {"sender": "player", "target": "pulaski", "subject": "Re: Zerknij na to.", "body": "Dobrze, już się za to zabieram.\n\nGreg, Gracz"},
	"2": {"sender": "player", "target": "maslo", "subject": "Re: Pożar", "body": "Ok, wartościowa informacja. Pracuję nad tym.\nDziękuję za pomoc przy akcji gaśniczej.\n\nGreg"},
	"3": {"sender": "player", "target": "slubicka", "subject": "Okoliczności pożaru", "body": "Dzień dobry. Prowadzimy analizę zdarzeń związanych z pożarem Państwa biurowca. Czy posiada Pani informacje, które mogłyby pomóc ustalić przyczynę zdarzenia\n\nGreg, śledczy sprawy nr 6721", "reply": "C"},
	"4": {"sender": "player", "target": "slubicka", "subject": "Monitoring budynku", "body": "Dzień dobry, \nCzy posiada Pani dostęp do nagrań monitoringu z dnia pożaru?\n\nGreg, śledczy sprawy nr 6721", "reply": "D"},
	"5": {"sender": "player", "target": "slubicka", "subject": "Administrator budynku", "body": "Dzień dobry, \nKto odpowiada za systemy techniczne budynku?\n\nGreg, śledczy sprawy nr 6721", "reply": "E"},
	"6": {"sender": "player", "target": "slubicka", "subject": "Lokalizacja", "body": "Czy pani była w Krakowie gdy to się działo?\n\nGreg, śledczy sprawy nr 6721", "reply": "F"},
	"7": {"sender": "player", "target": "slubicka", "subject": "Pytanie", "body": "A kto w firmie ma takie uprawnienia?\n\nGreg, śledczy sprawy nr 6721", "reply": "E"},
	"8": {"sender": "player", "target": "slubicka", "subject": "Czy w firmie ostatnio działo się coś podejrzanego?", "body": ".", "reply": "G"},
	"9": {"sender": "player", "target": "glus", "subject": "Pilny kontakt", "body": "Dzień dobry. Potrzebujemy dostępu do monitoringu budynku PolyServers.\n\nGreg, Śledczy sprawy 6721", "reply": ""},
	"10": {"sender": "player", "target": "glus", "subject": "Dochodzenie policyjne", "body": "Dzień dobry. Prosimy o pilną odpowiedź. Proszę nam dać klucz do zaszyfrowanych nagrań z monitoringu!\n\nGreg, Śledczy sprawy 6721", "reply": ""},
	"11": {"sender": "player", "target": "rumian", "subject": "Przebieg zdarzeń", "body": "Co robił pan bezpośrednio przed wybuchem pożaru?\n\nGreg, śledczy sprawy 6721", "reply": "H"},
	"12": {"sender": "player", "target": "rumian", "subject": "Monitoring", "body": "Czy zauważył pan coś nietypowego na nagraniach z monitoringu?\n\nGreg, śledczy sprawy 6721", "reply": "I"},
	"13": {"sender": "player", "target": "rumian", "subject": "Zabezpieczenia", "body": "Jak działa system bezpieczeństwa w waszym biurowcu?\n\nGreg, śledczy sprawy 6721", "reply": "J"},
	"14": {"sender": "player", "target": "pingwin", "subject": "Pożar", "body": "Czy zauważyła Pani coś nietypowego podczas pożaru?\n\nGreg, śledczy sprawy nr 6721", "reply": "L"},
	"15": {"sender": "player", "target": "pingwin", "subject": "System zamków", "body": "Radosław Rumian wspomniał o problemach z elektronicznymi zamkami. Czy może Pani to rozwinąć?\n\nGreg, śledczy sprawy nr 6721", "reply": "M"},
	"16": {"sender": "player", "target": "pingwin", "subject": "Nietypowe Zdarzenia.", "body": "Czy przed pożarem zauważyła Pani coś podejrzanego?", "reply": "N"},
}

# --- Dynamiczny Stan Gry ---
var active_contacts = ["pulaski", "maslo", "slubicka", "glus", "rumian", "pingwin"]
var conversation_histories = {} # contact_id : Array of mail_ids
var global_mailbox_history = [] # Chronologiczna lista WSZYSTKICH odebranych/wysłanych maili
var current_contact = ""
var current_selected_reply_id = ""

# Zmienne śledzące postęp w śledztwie
var rumian_answered = [] 
var glus_sent_mails = [] 
var seen_j_mail = false  

func _ready():
	for contact in active_contacts:
		conversation_histories[contact] = []
	
	# Maile początkowe w skrzynce
	receive_npc_mail("A")
	receive_npc_mail("B")
	
	setup_contacts_ui()
	setup_recipient_dropdown()
	rebuild_global_mailbox_ui()
	
	# Połączenia sygnałów dla przycisków wyboru odpowiedzi w HBox
	for button in nowa_wiadomosc_panel.get_children():
		if button is Button:
			button.pressed.connect(_on_reply_option_button_pressed.bind(button))
			
	wyslij_btn.pressed.connect(_on_wyslij_btn_pressed)
	btn_odpowiedz.pressed.connect(_on_btn_odpowiedz_pressed)
	wybieranie_odbiorcy.item_selected.connect(_on_recipient_dropdown_changed)
	
	# Wybierz pierwszego kontaktu na starcie
	select_contact("pulaski")

# --- Zarządzanie UI ---

func setup_contacts_ui():
	for child in kontakty_vbox.get_children():
		child.queue_free()
		
	for contact_id in active_contacts:
		# 1. Tworzymy poziomy kontener dla awatara i przycisku
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8) # Odstęp między awatarem a tekstem
		
		# 2. Tworzymy i konfigurujemy TextureRect dla awatara
		var avatar_rect = TextureRect.new()
		var texture_path = AVATARS.get(contact_id, AVATARS["default"])
		
		if ResourceLoader.exists(texture_path):
			avatar_rect.texture = load(texture_path)
		else:
			avatar_rect.texture = load(AVATARS["default"])
			
		avatar_rect.custom_minimum_size = AVATAR_SIZE
		avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		
		# Opcjonalne: Jeśli chcesz, aby silnik sam przyciął kwadrat do kółka, 
		# najprościej zrobić to za pomocą gotowej małej okrągłej maski/tekstury, 
		# ale dobre wyskalowanie załatwia 90% estetyki.
		
		# 3. Tworzymy przycisk z tekstem
		var btn = Button.new()
		btn.text = CONTACTS[contact_id]["name"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(select_contact.bind(contact_id))
		
		# 4. Składamy wszystko razem
		hbox.add_child(avatar_rect)
		hbox.add_child(btn)
		kontakty_vbox.add_child(hbox)

func setup_recipient_dropdown():
	wybieranie_odbiorcy.clear()
	wybieranie_odbiorcy.add_item("--- Wybierz odbiorcę ---", 0)
	var idx = 1
	for contact_id in active_contacts:
		wybieranie_odbiorcy.add_item(CONTACTS[contact_id]["name"], idx)
		wybieranie_odbiorcy.set_item_metadata(idx, contact_id)
		idx += 1

func select_contact(contact_id: String):
	current_contact = contact_id
	tresc_maila.text = ""
	btn_odpowiedz.visible = false
	
	# Aktualizacja dropdownu odbiorcy
	for i in range(wybieranie_odbiorcy.item_count):
		if wybieranie_odbiorcy.get_item_metadata(i) == contact_id:
			wybieranie_odbiorcy.selected = i
			break
			
	update_reply_buttons_ui()

# Odświeża cały panel MaileVBox zachowując nową chronologię (najnowsze na górze)
func rebuild_global_mailbox_ui():
	for child in maile_vbox.get_children():
		child.queue_free()
		
	# Iterujemy od tyłu, aby najświeższe dodane elementy były generowane jako pierwsze
	for i in range(global_mailbox_history.size() - 1, -1, -1):
		var mail_id = global_mailbox_history[i]
		var mail_data = EMAILS[mail_id]
		var btn = Button.new()
		
		var sender_name = ""
		if mail_data.has("target"):
			sender_name = "Ja -> " + CONTACTS[mail_data["target"]]["name"]
		else:
			sender_name = CONTACTS[mail_data["sender"]]["name"]
			
		btn.text = "[%s] %s" % [sender_name, mail_data["subject"]]
		btn.pressed.connect(display_email_content.bind(mail_id))
		maile_vbox.add_child(btn)

func display_email_content(mail_id: String):
	var mail_data = EMAILS[mail_id]
	var sender_name = "Ty" if mail_data.has("target") else CONTACTS[mail_data["sender"]]["name"]
	
	tresc_maila.text = "[b]Od:[/b] %s\n[b]Temat:[/b] %s\n\n%s" % [sender_name, mail_data["subject"], mail_data["body"]]
	
	if mail_id == "J":
		seen_j_mail = true
		update_reply_buttons_ui()
		
	if not mail_data.has("target") and mail_id != "SUGESTIA_BARTEK":
		btn_odpowiedz.visible = true
	else:
		btn_odpowiedz.visible = false

func update_reply_buttons_ui():
	for child in nowa_wiadomosc_panel.get_children():
		if child is Button:
			child.visible = false
			child.text = ""
	
	current_selected_reply_id = ""
	var available_p_mails = get_available_replies_for_contact(current_contact)
	
	var buttons = []
	for child in nowa_wiadomosc_panel.get_children():
		if child is Button:
			buttons.append(child)
			child.modulate = Color.WHITE # Reset podświetlenia przycisków
			
	for i in range(min(available_p_mails.size(), buttons.size())):
		var p_mail_id = available_p_mails[i]
		buttons[i].text = "%s: %s" % [p_mail_id, EMAILS[p_mail_id]["subject"]]
		buttons[i].set_meta("p_mail_id", p_mail_id)
		buttons[i].visible = true

# --- Logika Grafu Dialogowego ---

func get_available_replies_for_contact(contact_id: String) -> Array:
	var options = []
	var history = conversation_histories[contact_id]
	
	match contact_id:
		"pulaski":
			if "A" in history and not "1" in history:
				options.append("1")
		"maslo":
			if "B" in history and not "2" in history:
				options.append("2")
		"slubicka":
			if history.is_empty():
				options = ["3", "4", "5"]
			else:
				var last_mail = history[-1]
				if last_mail == "C": options = ["4", "5", "6"]
				elif last_mail == "D": options = ["5", "6", "7"]
				elif last_mail == "F": options = ["4", "8"]
		"glus":
			if not "9" in glus_sent_mails: options.append("9")
			if not "10" in glus_sent_mails: options.append("10")
		"rumian":
			if rumian_answered.size() < 3:
				if not "11" in history: options.append("11")
				if not "12" in history: options.append("12")
				if not "13" in history: options.append("13")
		"pingwin":
			if not "14" in history:
				options.append("14")
			if seen_j_mail and not "15" in history:
				options.append("15")
			if ("L" in history or "M" in history) and not "16" in history:
				options = ["16"]
				
	return options

# --- Obsługa Akcji Gracza ---

# Usprawnienie 1: Wybranie przycisku natychmiast wyświetla treść w oknie głównym
func _on_reply_option_button_pressed(button: Button):
	if button.has_meta("p_mail_id"):
		current_selected_reply_id = button.get_meta("p_mail_id")
		
		# Podświetlenie przycisku wyboru
		for child in nowa_wiadomosc_panel.get_children():
			if child is Button:
				child.modulate = Color.WHITE
		button.modulate = Color.GREEN_YELLOW
		
		# Wyświetlenie pełnego podglądu maila przed wysłaniem
		var mail_data = EMAILS[current_selected_reply_id]
		tresc_maila.text = "[b]Do:[/b] %s (Podgląd wiadomości)\n[b]Temat:[/b] %s\n\n%s" % [CONTACTS[mail_data["target"]]["name"], mail_data["subject"], mail_data["body"]]
		btn_odpowiedz.visible = false

func _on_wyslij_btn_pressed():
	if current_selected_reply_id == "":
		return 
		
	send_player_mail(current_selected_reply_id)

func _on_btn_odpowiedz_pressed():
	nowa_wiadomosc_panel.grab_focus()

func _on_recipient_dropdown_changed(index: int):
	if index == 0: return
	var selected_contact_id = wybieranie_odbiorcy.get_item_metadata(index)
	select_contact(selected_contact_id)

# --- Przetwarzanie wiadomości ---

func send_player_mail(p_mail_id: String):
	var mail_data = EMAILS[p_mail_id]
	var contact_id = mail_data["target"]
	
	conversation_histories[contact_id].append(p_mail_id)
	global_mailbox_history.append(p_mail_id) # Zapis do globalnej skrzynki
	
	if contact_id == "glus":
		glus_sent_mails.append(p_mail_id)
		
	# Aktualizacja UI skrzynki i czyszczenie tekstu po wysłaniu
	rebuild_global_mailbox_ui()
	select_contact(contact_id)
	
	wyslij_btn.disabled = true
	await get_tree().create_timer(1.2).timeout
	wyslij_btn.disabled = false
	
	trigger_npc_response(p_mail_id, contact_id)

func trigger_npc_response(p_mail_id: String, contact_id: String):
	var p_mail_data = EMAILS[p_mail_id]
	
	match contact_id:
		"glus":
			if glus_sent_mails.has("9") and glus_sent_mails.has("10"):
				receive_npc_mail("SUGESTIA_BARTEK")
		"rumian":
			var reply_letter = p_mail_data["reply"]
			receive_npc_mail(reply_letter)
			if not reply_letter in rumian_answered:
				rumian_answered.append(reply_letter)
			
			if rumian_answered.size() == 3:
				await get_tree().create_timer(1.5).timeout
				receive_npc_mail("K")
		_:
			if p_mail_data.has("reply") and p_mail_data["reply"] != "":
				receive_npc_mail(p_mail_data["reply"])

	if current_contact == contact_id:
		select_contact(contact_id)

func receive_npc_mail(mail_id: String):
	var mail_data = EMAILS[mail_id]
	var sender = mail_data["sender"]
	conversation_histories[sender].append(mail_id)
	global_mailbox_history.append(mail_id) # Zapis do globalnej skrzynki
	
	rebuild_global_mailbox_ui() # Natychmiastowe odświeżenie listy z nowym mailem na górze
