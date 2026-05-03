extends Area2D

var kierunek = 1
var predkosc = 80.0
var zasieg = 150.0
var start_y

func _ready():
	start_y = position.y
	# Każdy ogień startuje z losowym kierunkiem żeby nie szły razem
	kierunek = [-1, 1].pick_random()

func _process(delta):
	position.y += kierunek * predkosc * delta
	
	if position.y > start_y + zasieg:
		kierunek = -1
	elif position.y < start_y - zasieg:
		kierunek = 1

func _on_body_entered(body):
	if body.is_in_group("gracz"):
		print("PRZEGRANA! Spłonąłeś! 🔥")
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
