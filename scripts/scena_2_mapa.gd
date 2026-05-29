extends Control
const marker_scale : Vector2 = Vector2(0.6, 0.6)
const map_start_in_px = Vector2(580, 0)
var player_marker = Sprite2D.new()
var target_marker = Sprite2D.new()
const map_scale = 0.0105 # relative to meters

func _ready():
	player_marker.texture = load("res://assets/graphics/scena_1/Arrow_icon_green.svg")
	target_marker.texture = load("res://assets/graphics/scena_1/wykrzyknik.svg")
	player_marker.scale = marker_scale
	target_marker.scale = marker_scale
	self.add_child(player_marker)
	self.add_child(target_marker)

func set_player(position_t : Vector2, rotation_i):
	player_marker.position = position_t * find_child("MapSprite").scale * map_scale + map_start_in_px
	player_marker.rotation = rotation_i
	
func set_target(position_t : Vector2 ):
	target_marker.position = position_t * find_child("MapSprite").scale * map_scale + map_start_in_px
	print(target_marker.position)
	
func _input(event):
	if event is InputEventKey and event.keycode == KEY_M:
		self.visible = event.pressed
