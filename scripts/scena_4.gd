extends Control

# Referencje do węzłów
@onready var btn_mail = $CanvasLayer/"Menu Aplikacji"/BtnMail
@onready var btn_sms = $CanvasLayer/"Menu Aplikacji"/BtnSMS
@onready var btn_monitoring = $CanvasLayer/"Menu Aplikacji"/BtnMonitoring

@onready var okno_mail = $CanvasLayer/OknoMail
@onready var okno_tel = $CanvasLayer/Telefon
@onready var okno_monitoring = $CanvasLayer/OknoMonitoring

@onready var zegar_label = $CanvasLayer/"Pasek Górny"/Zegar

# Stan aktywnego okna
var current_window = "none"

func _ready() -> void:
	# Podłącz przyciski menu
	btn_mail.pressed.connect(_on_mail_clicked)
	btn_sms.pressed.connect(_on_sms_clicked)
	btn_monitoring.pressed.connect(_on_monitoring_clicked)
	
	# Ustaw mail jako domyślne okno
	_show_mail_window()
	_update_clock()

func _process(delta: float) -> void:
	_update_clock()

func _update_clock() -> void:
	var now = Time.get_datetime_dict_from_system()
	zegar_label.text = "%02d:%02d" % [now.hour, now.minute]

func _on_mail_clicked() -> void:
	_show_mail_window()

func _on_sms_clicked() -> void:
	_show_sms_window()

func _on_monitoring_clicked() -> void:
	_show_monitoring_window()

func _show_mail_window() -> void:
	if current_window == "mail":
		return
	
	okno_mail.visible = true
	okno_tel.visible = false
	okno_monitoring.visible = false
	current_window = "mail"
	
	# Zmień styl przycisku
	_update_button_styles()

func _show_sms_window() -> void:
	if current_window == "sms":
		return
	
	okno_mail.visible = false
	okno_tel.visible = true
	okno_monitoring.visible = false
	current_window = "sms"
	
	# Zmień styl przycisku
	_update_button_styles()

func _show_monitoring_window() -> void:
	if current_window == "monitoring":
		return
	
	okno_mail.visible = false
	okno_tel.visible = false
	okno_monitoring.visible = true
	current_window = "monitoring"
	
	# Zmień styl przycisku
	_update_button_styles()

func _update_button_styles() -> void:
	# Zresetuj style wszystkich przycisków
	btn_mail.modulate = Color.WHITE
	btn_sms.modulate = Color.WHITE
	btn_monitoring.modulate = Color.WHITE
	
	# Wyróżnij aktywny przycisk
	match current_window:
		"mail":
			btn_mail.modulate = Color.YELLOW
		"sms":
			btn_sms.modulate = Color.YELLOW
		"monitoring":
			btn_monitoring.modulate = Color.YELLOW
