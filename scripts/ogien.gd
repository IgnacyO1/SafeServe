extends Area2D

var kierunek = 1
var predkosc = 80.0
var zasieg = 150.0
var start_y

func _ready():
	add_to_group("ogien")
	start_y = position.y
	kierunek = [-1, 1].pick_random()
	
var czas_klatki = 0.0
var fps = 10.0

func _process(delta):
	czas_klatki += delta
	if czas_klatki >= 1.0 / fps:
		czas_klatki -= 1.0 / fps
		var spr = $Sprite2D
		if spr:
			spr.frame = (spr.frame + 1) % spr.hframes

func _on_body_entered(body):
	if body.is_in_group("gracz"):
		set_deferred("monitoring", false)
		
		# Wywołaj przegrana_spalenie() na scenie głównej jeśli istnieje
		var scena = get_tree().current_scene
		if scena and scena.has_method("przegrana_spalenie"):
			scena.przegrana_spalenie()
		else:
			# Fallback: czarny ekran i powrót do menu
			var canvas = CanvasLayer.new()
			canvas.layer = 100
			get_tree().root.add_child(canvas)
			
			var fade_rect = ColorRect.new()
			fade_rect.color = Color(0, 0, 0, 0)
			fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			canvas.add_child(fade_rect)
			
			var tw = create_tween()
			tw.tween_property(fade_rect, "color:a", 1.0, 1.0)
			await tw.finished
			
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
