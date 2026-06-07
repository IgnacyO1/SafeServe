extends Node2D

var single_scene_path = "res://scenes/scena_7.tscn"
var multiplayer_scene_path = "res://scenes/scena_7_multiplayer_version.tscn"

@onready var btn_single = $VBoxContainer/BtnSingle
@onready var btn_multiplayer = $VBoxContainer/BtnJoin # Używamy BtnJoin jako wejścia do VPS
@onready var btn_exit = $VBoxContainer/BtnExit

func _ready() -> void:
	btn_single.pressed.connect(_on_single_pressed)
	btn_multiplayer.pressed.connect(_on_multiplayer_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func _on_single_pressed():
	print("[MENU] Uruchamianie gry lokalnej (Single Player)...")
	get_tree().change_scene_to_file(single_scene_path)

func _on_multiplayer_pressed():
	print("[MENU] Łączenie z globalnym serwerem VPS...")
	var game_instance = load(multiplayer_scene_path).instantiate()
	
	# Wstrzykujemy instancję struktury (wraz z nakładkami i viewportem) do drzewa gry
	get_tree().root.add_child(game_instance)
	
	# Szukamy w głąb struktury węzła, który posiada funkcję run_as_client()
	var success = _find_and_start_client(game_instance)
	
	if not success:
		print("CRITICAL ERROR: Nie znaleziono węzła ze skryptem 'scena_7_world_multiplayer.gd' w strukturze sceny!")
	
	# Czyścimy menu, bo gra ruszyła w tle
	queue_free()

# Funkcja przeszukująca drzewo węzłów w głąb – odporna na zmiany układu UI i SubViewporty
func _find_and_start_client(current_node: Node) -> bool:
	if current_node.has_method("run_as_client"):
		current_node.run_as_client()
		return true
		
	for child in current_node.get_children():
		if _find_and_start_client(child):
			return true
			
	return false

func _on_exit_pressed():
	get_tree().quit()
