extends Control

# Referencje do węzłów
@onready var btn_mail = $CanvasLayer/"Menu Aplikacji"/BtnMail
@onready var btn_sms = $CanvasLayer/"Menu Aplikacji"/BtnSMS
@onready var btn_monitoring = $CanvasLayer/"Menu Aplikacji"/BtnMonitoring

@onready var okno_mail = $CanvasLayer/OknoMail
@onready var okno_tel = $CanvasLayer/Telefon
@onready var okno_monitoring = $CanvasLayer/OknoMonitoring

@onready var zegar_label = $CanvasLayer/"Pasek Górny"/Zegar
@onready var canvas_layer = $CanvasLayer  # Potrzebujemy referencji do CanvasLayer, aby przypiąć tam ekran

# Stan aktywnego okna
var current_window = "none"
var mozna_klikac = false # Blokada interakcji podczas intro

func _ready() -> void:
	# Podłącz przyciski menu
	btn_mail.pressed.connect(_on_mail_clicked)
	btn_sms.pressed.connect(_on_sms_clicked)
	btn_monitoring.pressed.connect(_on_monitoring_clicked)
	
	# Ustaw mail jako domyślne okno
	_show_mail_window()
	_update_clock()
	
	# Dynamiczne stworzenie i uruchomienie ekranu wstępu
	_stworz_i_uruchom_intro()

func _process(delta: float) -> void:
	_update_clock()

func _update_clock() -> void:
	var now = Time.get_datetime_dict_from_system()
	zegar_label.text = "%02d:%02d" % [now.hour, now.minute]

# Dynamiczne tworzenie czarnego ekranu i napisu
func _stworz_i_uruchom_intro() -> void:
	mozna_klikac = false
	
	# 1. Tworzenie czarnego tła (ColorRect)
	var dynamiczny_ekran = ColorRect.new()
	dynamiczny_ekran.color = Color.BLACK
	# Rozciągnięcie na cały ekran (odpowiednik Full Rect w GUI)
	dynamiczny_ekran.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 2. Tworzenie napisu (Label)
	var dynamiczny_napis = Label.new()
	dynamiczny_napis.text = "CZĘŚĆ 2: Śledztwo"
	# Wyśrodkowanie napisu na ekranie
	dynamiczny_napis.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dynamiczny_napis.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dynamiczny_napis.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# (Opcjonalnie) Jeśli chcesz zmienić wielkość czcionki bez pliku .tres, 
	# możesz odkomentować poniższą linijkę (działa w Godot 4):
	dynamiczny_napis.add_theme_font_size_override("font_size", 50)

	# 3. Dodanie węzłów do drzewa sceny
	dynamiczny_ekran.add_child(dynamiczny_napis)
	canvas_layer.add_child(dynamiczny_ekran) # Wrzucamy na samą górę CanvasLayer
	
	# 4. Animacja za pomocą Tweena
	var tween = create_tween()
	
	# Czekaj 2 sekundy (czarny ekran z napisem)
	tween.tween_interval(2.0)
	
	# Płynne zanikanie (fade out) przez 1.5 sekundy
	tween.tween_property(dynamiczny_ekran, "modulate:a", 0.0, 1.5)
	
	# Po zakończeniu: odblokuj grę i całkowicie usuń obiekty z pamięci
	tween.tween_callback(func():
		mozna_klikac = true
		dynamiczny_ekran.queue_free() # Usuwa ColorRect i Label ze sceny
	)

# Blokady klikania, dopóki intro trwa
func _on_mail_clicked() -> void:
	if not mozna_klikac: return
	_show_mail_window()

func _on_sms_clicked() -> void:
	if not mozna_klikac: return
	_show_sms_window()

func _on_monitoring_clicked() -> void:
	if not mozna_klikac: return
	_show_monitoring_window()

func _show_mail_window() -> void:
	if current_window == "mail":
		return
	
	okno_mail.visible = true
	okno_tel.visible = false
	okno_monitoring.visible = false
	current_window = "mail"
	_update_button_styles()

func _show_sms_window() -> void:
	if current_window == "sms":
		return
	
	okno_mail.visible = false
	okno_tel.visible = true
	okno_monitoring.visible = false
	current_window = "sms"
	_update_button_styles()

func _show_monitoring_window() -> void:
	if current_window == "monitoring":
		return
	
	okno_mail.visible = false
	okno_tel.visible = false
	okno_monitoring.visible = true
	current_window = "monitoring"
	_update_button_styles()

func _update_button_styles() -> void:
	btn_mail.modulate = Color.WHITE
	btn_sms.modulate = Color.WHITE
	btn_monitoring.modulate = Color.WHITE
	
	match current_window:
		"mail":
			btn_mail.modulate = Color.YELLOW
		"sms":
			btn_sms.modulate = Color.YELLOW
		"monitoring":
			btn_monitoring.modulate = Color.YELLOW
