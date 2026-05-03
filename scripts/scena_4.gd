extends Node2D

@onready var label_czas = $HUD/LabelCzas

var czas = 60.0
var gra_aktywna = true

const OGIEN_SCENA = preload("res://scenes/ogien.tscn")

# Pozycje ogni wzdłuż korytarza
var pozycje_ogni = [
	Vector2(1200, 540),
	Vector2(2200, 540),
	Vector2(3200, 540),
	Vector2(4200, 540),
	Vector2(5200, 540),
	Vector2(6200, 540),
	Vector2(7200, 540),
]

func _ready():
	for poz in pozycje_ogni:
		var ogien = OGIEN_SCENA.instantiate()
		ogien.position = poz
		add_child(ogien)

func _process(delta: float) -> void:
	if not gra_aktywna:
		return
	czas -= delta
	label_czas.text = "Czas: " + str(int(czas))
	if czas <= 10:
		label_czas.modulate = Color.RED
	if czas <= 0:
		gra_aktywna = false
		label_czas.text = "Czas: 0"
		print("PRZEGRANA! Czas minął! 💀")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
