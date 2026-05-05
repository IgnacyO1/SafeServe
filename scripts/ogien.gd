extends Area2D

var kierunek = 1
var predkosc = 80.0
var zasieg = 150.0
var start_y

func _ready():
	add_to_group("ogien")
	start_y = position.y
	kierunek = [-1, 1].pick_random()

func _process(delta):
	# Zakomentowałem poruszanie się, żeby łatwiej było do niego podejść i ugasić "pod E"
	# Jeśli wolisz żeby uciekał, odkomentuj:
	# position.y += kierunek * predkosc * delta
	# if position.y > start_y + zasieg:
	# 	kierunek = -1
	# elif position.y < start_y - zasieg:
	# 	kierunek = 1
	pass

func _on_body_entered(body):
	if body.is_in_group("gracz"):
		print("Dotknąłeś ognia, ale masz maskę? Nieważne, gaś pożar pod E (zanim padniesz)!")
		# Jeśli nadal chcesz śmierci o natychmiastowym dotyku:
		# get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

