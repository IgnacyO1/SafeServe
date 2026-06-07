extends Control

# --- Ścieżki do węzłów interfejsu ---
@onready var btn_file: Button = $BtnFile
@onready var popup: PanelContainer = $Popup
@onready var line_edit_passwd: LineEdit = $Popup/VBoxContainer/LineEditPasswd
@onready var response_label: Label = $Popup/VBoxContainer/ResponseLabel
@onready var btn_close: Button = $Popup/BtnClose

# --- Stałe ---
const CORRECT_PASSWORD = "zaq1"
const NEXT_SCENE_PATH = "res://scenes/scena_5.tscn"

func _ready() -> void:
	# Ukrywamy popup na starcie i czyścimy stare teksty
	popup.visible = false
	response_label.text = ""
	line_edit_passwd.text = ""
	
	# Podpinanie sygnałów przycisków
	btn_file.pressed.connect(_on_btn_file_pressed)
	btn_close.pressed.connect(_on_btn_close_pressed)
	
	# Sygnał aktywowany, gdy gracz wciśnie ENTER wewnątrz LineEdit
	line_edit_passwd.text_submitted.connect(_on_password_submitted)

# --- Obsługa otwierania i zamykania okna ---
func _on_btn_file_pressed() -> void:
	popup.visible = true
	response_label.text = ""
	line_edit_passwd.text = ""
	line_edit_passwd.grab_focus() # Od razu aktywujemy pole tekstowe, żeby gracz mógł pisać

func _on_btn_close_pressed() -> void:
	popup.visible = false

# --- Weryfikacja hasła ---
func _on_password_submitted(submitted_text: String) -> void:
	# .to_lower() zapewnia brak wrażliwości na wielkość liter (case-insensitive)
	if submitted_text.to_lower() == CORRECT_PASSWORD.to_lower():
		response_label.add_theme_color_override("font_color", Color.GREEN)
		response_label.text = "Hasło poprawne. Odszyfrowywanie..."
		
		# Chwila pauzy na efekt wizualny przed zmianą sceny
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	else:
		response_label.add_theme_color_override("font_color", Color.RED)
		response_label.text = "Niepoprawne hasło."
		line_edit_passwd.text = "" # Czyszczenie pola po złym haśle
