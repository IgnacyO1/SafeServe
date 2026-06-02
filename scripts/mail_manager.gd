extends Control

# Referencje do węzłów UI
@onready var kontakty_vbox = $KontaktyPanel/KontaktyScroll/KontaktyVBox
@onready var maile_vbox = $MailePanel/MaileScroll/MaileVBox
@onready var tresci_label = $TreśćPanel/TreśćMaila
@onready var opcja_btn1 = $NowaWiadomośćPanel/OpcjaBtn1
@onready var opcja_btn2 = $NowaWiadomośćPanel/OpcjaBtn2
@onready var opcja_btn3 = $NowaWiadomośćPanel/OpcjaBtn3

# Dane
var contacts: Array = []
var mail_tree: Dictionary = {}
var received_mails: Array = []
var sent_mails: Array = []
var current_selected_mail: Dictionary = {}
var current_response_tree: Dictionary = {}
var current_recipient: Dictionary = {}
var message_options: Array = []  # Przechowuje dostępne opcje wiadomości
var is_sending_mode: bool = false  # True gdy wysyłamy mail, False gdy odzyskujemy


func _ready() -> void:
	_load_data()
	_initialize_ui()
	_create_contact_buttons()
	_load_initial_mails()
	
	# Podłącz przyciski opcji
	opcja_btn1.pressed.connect(_on_option_button_pressed.bindv([0]))
	opcja_btn2.pressed.connect(_on_option_button_pressed.bindv([1]))
	opcja_btn3.pressed.connect(_on_option_button_pressed.bindv([2]))

func _load_data() -> void:
	# Załaduj kontakty
	var contacts_file = FileAccess.open("res://data/contacts.json", FileAccess.READ)
	if contacts_file:
		var contacts_data = JSON.parse_string(contacts_file.get_as_text())
		if contacts_data:
			contacts = contacts_data.get("contacts", [])
	
	# Załaduj drzewo odpowiedzi
	var tree_file = FileAccess.open("res://data/mail_responses_tree.json", FileAccess.READ)
	if tree_file:
		var tree_data = JSON.parse_string(tree_file.get_as_text())
		if tree_data:
			mail_tree = tree_data.get("response_trees", {})
			var initial_emails = tree_data.get("initial_emails", [])
			for email in initial_emails:
				received_mails.append(email)

func _initialize_ui() -> void:
	# Ukryj przyciski opcji na starcie
	opcja_btn1.visible = false
	opcja_btn2.visible = false
	opcja_btn3.visible = false
	
	# Pokaż powitanie
	tresci_label.clear()
	tresci_label.append_text("[b]Poczta e-mail[/b]\n\n")
	tresci_label.append_text("Wybierz mail z listy lub kontakt z lewej strony, aby wysłać wiadomość.")

func _create_contact_buttons() -> void:
	# Wyczyść poprzednie przyciski
	for child in kontakty_vbox.get_children():
		child.queue_free()
	
	# Utwórz przycisk dla każdego kontaktu
	for contact in contacts:
		var btn = Button.new()
		btn.text = "%s %s" % [contact.first_name, contact.last_name]
		btn.custom_minimum_size = Vector2(350, 60)
		btn.pressed.connect(_on_contact_selected.bindv([contact]))
		kontakty_vbox.add_child(btn)

func _load_initial_mails() -> void:
	_refresh_mail_list()

func _refresh_mail_list() -> void:
	# Wyczyść listę maili
	for child in maile_vbox.get_children():
		child.queue_free()
	
	# Wyczyść dynamiczne przyciski powrotu
	for child in opcja_btn1.get_parent().get_children():
		if child.name == "BtnPowrot":
			child.queue_free()
	
	# Ukryj przyciski opcji
	opcja_btn1.visible = false
	opcja_btn2.visible = false
	opcja_btn3.visible = false
	
	# Pokaż okno listy maili
	tresci_label.clear()
	
	# Wyświetl wszystkie otrzymane maile
	for mail in received_mails:
		var btn = Button.new()
		var subject = mail.get("subject", "Brak tematu")
		var from_name = mail.get("from_name", "Nieznany nadawca")
		btn.text = "[%s] %s" % [from_name, subject]
		btn.custom_minimum_size = Vector2(700, 50)
		btn.pressed.connect(_on_mail_selected.bindv([mail]))
		maile_vbox.add_child(btn)

func _on_contact_selected(contact: Dictionary) -> void:
	# Wyświetl informacje o kontakcie i opcje wysłania wiadomości
	tresci_label.clear()
	tresci_label.append_text("=== KONTAKT ===\n\n")
	tresci_label.append_text("[b]%s %s[/b]\n" % [contact.first_name, contact.last_name])
	tresci_label.append_text("Email: %s\n" % contact.email)
	if contact.get("phone"):
		tresci_label.append_text("Telefon: %s\n" % contact.phone)
	tresci_label.append_text("\n%s\n" % contact.description)
	
	# Ustaw odborcę w opcjach wysyłania
	_set_current_recipient(contact)

func _on_mail_selected(mail: Dictionary) -> void:
	current_selected_mail = mail
	_display_mail_content(mail)

func _display_mail_content(mail: Dictionary) -> void:
	tresci_label.clear()
	
	var from_name = mail.get("from_name", "Nieznany")
	var subject = mail.get("subject", "")
	var date = mail.get("date", "")
	var time = mail.get("time", "")
	
	tresci_label.append_text("[b]Od:[/b] %s\n" % from_name)
	tresci_label.append_text("[b]Temat:[/b] %s\n" % subject)
	tresci_label.append_text("[b]Data:[/b] %s %s\n\n" % [date, time])
	
	# Załaduj drzewo odpowiedzi dla tego maila
	var tree_key = mail.get("tree_key", "")
	if tree_key and tree_key in mail_tree:
		current_response_tree = mail_tree[tree_key]
		var initial_message = current_response_tree.get("initial_message", "")
		tresci_label.append_text("[b]Wiadomość:[/b]\n%s\n\n" % initial_message)
		
		# Pokaż opcje odpowiedzi
		_show_response_options()
	else:
		tresci_label.append_text("[Brak dostępnych opcji odpowiedzi]")

func _show_response_options() -> void:
	# Pokaż przyciski z opcjami odpowiedzi
	var options = current_response_tree.get("options", {})
	var options_keys = options.keys()
	message_options = options_keys
	is_sending_mode = false
	
	# Przypisz opcje do przycisków
	if options_keys.size() >= 1:
		opcja_btn1.text = options[options_keys[0]].get("text", "Opcja 1")
		opcja_btn1.visible = true
	else:
		opcja_btn1.visible = false
	
	if options_keys.size() >= 2:
		opcja_btn2.text = options[options_keys[1]].get("text", "Opcja 2")
		opcja_btn2.visible = true
	else:
		opcja_btn2.visible = false
	
	if options_keys.size() >= 3:
		opcja_btn3.text = options[options_keys[2]].get("text", "Opcja 3")
		opcja_btn3.visible = true
	else:
		opcja_btn3.visible = false

func _on_option_button_pressed(option_index: int) -> void:
	if is_sending_mode:
		_send_mail_with_option(option_index)
	else:
		_respond_to_mail_with_option(option_index)

func _send_mail_with_option(option_index: int) -> void:
	if option_index >= message_options.size():
		return
	
	var option_data = message_options[option_index]
	var topic = option_data.get("topic", "")
	
	# Utwórz nowy mail
	var new_mail = {
		"id": sent_mails.size() + 1,
		"to_id": current_recipient.get("id", 0),
		"to_name": "%s %s" % [current_recipient.first_name, current_recipient.last_name],
		"subject": topic,
		"date": _get_current_date(),
		"time": _get_current_time(),
		"is_sent": true
	}
	sent_mails.append(new_mail)
	
	# Pokaż potwierdzenie
	tresci_label.clear()
	tresci_label.append_text("[b]Wiadomość wysłana![/b]\n\n")
	tresci_label.append_text("Do: %s\n" % new_mail.to_name)
	tresci_label.append_text("Temat: %s\n" % new_mail.subject)
	
	# Ukryj przyciski opcji
	opcja_btn1.visible = false
	opcja_btn2.visible = false
	opcja_btn3.visible = false
	
	# Pokaż przycisk powrotu do listy kontaktów
	var btn_powrot = Button.new()
	btn_powrot.name = "BtnPowrotKontakty"
	btn_powrot.text = "Powrót do listy kontaktów"
	btn_powrot.custom_minimum_size = Vector2(350, 60)
	btn_powrot.pressed.connect(_on_back_to_contacts)
	opcja_btn1.add_sibling(btn_powrot)
	opcja_btn1.get_parent().move_child(btn_powrot, opcja_btn1.get_parent().get_child_count() - 1)

func _respond_to_mail_with_option(option_index: int) -> void:
	if option_index >= message_options.size():
		return
	
	var options_keys = message_options
	var option_key = options_keys[option_index]
	var option = current_response_tree.get("options", {}).get(option_key, {})
	
	# Pokaż odpowiedź NPC
	tresci_label.clear()
	
	var npc_response = option.get("npc_response", "Brak odpowiedzi")
	tresci_label.append_text("[b]Odpowiedź:[/b]\n%s\n\n" % npc_response)
	
	# Utwórz nowy mail z odpowiedzią
	var from_contact = _find_contact_by_name(current_selected_mail.get("from_name", ""))
	var response_mail = {
		"id": received_mails.size() + 1,
		"from_id": from_contact.get("id", 0) if from_contact else 0,
		"from_name": current_selected_mail.get("from_name", ""),
		"subject": "RE: %s" % current_selected_mail.get("subject", ""),
		"content": npc_response,
		"date": _get_current_date(),
		"time": _get_current_time(),
		"is_response": true
	}
	received_mails.append(response_mail)
	
	# Ukryj przyciski opcji
	opcja_btn1.visible = false
	opcja_btn2.visible = false
	opcja_btn3.visible = false
	
	# Pokaż przyciski powrotu
	var btn_powrot = Button.new()
	btn_powrot.name = "BtnPowrot"
	btn_powrot.text = "Powrót do listy maili"
	btn_powrot.custom_minimum_size = Vector2(350, 60)
	btn_powrot.pressed.connect(_refresh_mail_list)
	opcja_btn1.add_sibling(btn_powrot)
	opcja_btn1.get_parent().move_child(btn_powrot, opcja_btn1.get_parent().get_child_count() - 1)

func _set_current_recipient(contact: Dictionary) -> void:
	# Ustaw bieżącego odbiorcę
	current_recipient = contact
	is_sending_mode = true
	
	# Przygotuj opcje wysyłania z mail_tree
	var options_list = []
	for tree_key in mail_tree:
		var tree = mail_tree[tree_key]
		options_list.append({
			"topic": tree.get("topic", ""),
			"tree_key": tree_key
		})
	message_options = options_list
	
	# Przypisz opcje do przycisków
	if options_list.size() >= 1:
		opcja_btn1.text = "[1] " + options_list[0].get("topic", "Opcja 1")
		opcja_btn1.visible = true
	else:
		opcja_btn1.visible = false
	
	if options_list.size() >= 2:
		opcja_btn2.text = "[2] " + options_list[1].get("topic", "Opcja 2")
		opcja_btn2.visible = true
	else:
		opcja_btn2.visible = false
	
	if options_list.size() >= 3:
		opcja_btn3.text = "[3] " + options_list[2].get("topic", "Opcja 3")
		opcja_btn3.visible = true
	else:
		opcja_btn3.visible = false

func _find_contact_by_name(name: String) -> Dictionary:
	for contact in contacts:
		if contact.get("first_name", "") + " " + contact.get("last_name", "") == name:
			return contact
	return {}

func _on_back_to_contacts() -> void:
	# Wyczyść przycisk powrotu
	for child in opcja_btn1.get_parent().get_children():
		if child.name == "BtnPowrotKontakty":
			child.queue_free()
	
	# Pokaż listę kontaktów
	tresci_label.clear()
	_create_contact_buttons()

func _get_current_date() -> String:
	var now = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [now.year, now.month, now.day]

func _get_current_time() -> String:
	var now = Time.get_datetime_dict_from_system()
	return "%02d:%02d" % [now.hour, now.minute]
