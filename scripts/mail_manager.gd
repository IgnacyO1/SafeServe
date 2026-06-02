extends Control

# Referencje do węzłów UI
@onready var kontakty_vbox = $KontaktyPanel/KontaktyScroll/KontaktyVBox
@onready var maile_vbox = $MailePanel/MaileScroll/MaileVBox
@onready var tresci_label = $TreśćPanel/TreśćMaila
@onready var odbiorcy_button = $NowaWiadomośćPanel/OdbiorcaLista
@onready var temat_button = $NowaWiadomośćPanel/TematLista
@onready var tresc_input = $NowaWiadomośćPanel/TreśćInput
@onready var btn_wyslij = $NowaWiadomośćPanel/BtnWyślij

# Dane
var contacts: Array = []
var mail_tree: Dictionary = {}
var received_mails: Array = []
var sent_mails: Array = []
var current_selected_mail: Dictionary = {}
var current_response_tree: Dictionary = {}

# Style dla przycisków
#var contact_button_scene = preload("res://scenes/modal_button.tscn")

func _ready() -> void:
	_load_data()
	_initialize_ui()
	_create_contact_buttons()
	_load_initial_mails()
	btn_wyslij.pressed.connect(_send_reply)

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
	# Ukryj przyciski wysyłania, póki nie ma wybranego maila
	temat_button.visible = false
	tresc_input.visible = false
	btn_wyslij.visible = false
	
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
	
	# Wyczyść przycisk powrotu i opcje jeśli są
	for child in tresc_input.get_parent().get_children():
		if child.name.begins_with("OpcjaBtn") or child.name == "BtnPowrot":
			child.queue_free()
	
	# Pokaż okno listy maili
	tresci_label.clear()
	temat_button.visible = false
	tresc_input.visible = false
	btn_wyslij.visible = false
	
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
	# Wyczyść poprzednie przyciski opcji
	for child in tresc_input.get_parent().get_children():
		if child.name.begins_with("OpcjaBtn"):
			child.queue_free()
	
	temat_button.visible = false
	tresc_input.visible = false
	btn_wyslij.visible = false
	
	# Utwórz przyciski dla każdej opcji odpowiedzi
	var options = current_response_tree.get("options", {})
	var index = 0
	var parent_container = tresc_input.get_parent()
	for option_key in options:
		var option = options[option_key]
		var btn = Button.new()
		btn.name = "OpcjaBtn_%d" % index
		btn.text = option.get("text", "")
		btn.custom_minimum_size = Vector2(650, 50)
		btn.pressed.connect(_on_response_option_selected.bindv([option_key, option]))
		parent_container.add_child(btn)
		parent_container.move_child(btn, parent_container.get_child_count() - 1)
		index += 1

func _on_response_option_selected(option_key: String, option: Dictionary) -> void:
	# Wyczyść poprzednie przyciski opcji
	for child in tresc_input.get_parent().get_children():
		if child.name.begins_with("OpcjaBtn"):
			child.queue_free()
	
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
	_refresh_mail_list()
	
	# Pokaż przycisk powrotu
	var btn_powrot = Button.new()
	btn_powrot.name = "BtnPowrot"
	btn_powrot.text = "Powrót do listy maili"
	btn_powrot.pressed.connect(_refresh_mail_list)
	var parent_container = tresc_input.get_parent()
	parent_container.add_child(btn_powrot)

func _set_current_recipient(contact: Dictionary) -> void:
	# Wyczyść opcje wysyłania i przycisk powrotu jeśli są
	for child in tresc_input.get_parent().get_children():
		if child.name.begins_with("OpcjaBtn") or child.name == "BtnPowrot" or child.name == "BtnNowyMail":
			child.queue_free()
	
	# Ustaw odbiorcę i pokaż opcje wysyłania
	odbiorcy_button.clear()
	odbiorcy_button.add_item("%s %s" % [contact.first_name, contact.last_name])
	odbiorcy_button.set_item_metadata(0, contact)
	
	# Pokaż opcje tematu (możemy je pobrać z drzewa)
	temat_button.clear()
	temat_button.visible = true
	
	for tree_key in mail_tree:
		var tree = mail_tree[tree_key]
		var topic = tree.get("topic", "")
		temat_button.add_item(topic)
		temat_button.set_item_metadata(temat_button.get_item_count() - 1, tree_key)
	
	tresc_input.visible = true
	tresc_input.clear()
	btn_wyslij.visible = true

func _send_reply() -> void:
	var recipient_index = odbiorcy_button.get_selected()
	var recipient = odbiorcy_button.get_item_metadata(recipient_index)
	
	var topic_index = temat_button.get_selected()
	var topic = temat_button.get_item_text(topic_index)
	
	var content = tresc_input.text
	
	if content.is_empty():
		return
	
	# Utwórz nowy mail
	var new_mail = {
		"id": sent_mails.size() + 1,
		"to_id": recipient.get("id", 0),
		"to_name": "%s %s" % [recipient.first_name, recipient.last_name],
		"subject": topic,
		"content": content,
		"date": _get_current_date(),
		"time": _get_current_time(),
		"is_sent": true
	}
	sent_mails.append(new_mail)
	
	# Wyczyść formularz
	tresc_input.clear()
	temat_button.visible = false
	tresc_input.visible = false
	btn_wyslij.visible = false
	
	# Pokaż potwierdzenie
	tresci_label.clear()
	tresci_label.append_text("[b]Wiadomość wysłana![/b]\n\n")
	tresci_label.append_text("Do: %s\n" % new_mail.to_name)
	tresci_label.append_text("Temat: %s\n" % new_mail.subject)

func _find_contact_by_name(name: String) -> Dictionary:
	for contact in contacts:
		if contact.get("first_name", "") + " " + contact.get("last_name", "") == name:
			return contact
	return {}

func _get_current_date() -> String:
	var now = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [now.year, now.month, now.day]

func _get_current_time() -> String:
	var now = Time.get_datetime_dict_from_system()
	return "%02d:%02d" % [now.hour, now.minute]
