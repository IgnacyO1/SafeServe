extends CharacterBody2D

# Odległości w pikselach od punktu zero (głowy tramwaju) dla przedniego i tylnego wózka
var front_bogie_offset: float = 0.0
var rear_bogie_offset: float = 0.0

func setup(front_offset: float, rear_offset: float):
	front_bogie_offset = front_offset
	rear_bogie_offset = rear_offset

func update_position(curve: Curve2D, master_distance: float):
	# Oblicz pozycje wózków na linii życia (krzywej)
	var f_dist = master_distance - front_bogie_offset
	var r_dist = master_distance - rear_bogie_offset
	
	# Pobierz globalne pozycje z Curve2D za pomocą wbudowanego próbkowania dystansu
	var f_pos = curve.sample_baked(f_dist)
	var r_pos = curve.sample_baked(r_dist)
	
	# Matematyczny środek wagonu leży dokładnie pomiędzy wózkami
	global_position = (f_pos + r_pos) / 2.0
	
	# Obrót zgodny z kierunkiem jazdy segmentu
	rotation = (r_pos - f_pos).angle()
