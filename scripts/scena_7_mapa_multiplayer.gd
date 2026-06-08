extends Control

const marker_scale : Vector2 = Vector2(0.6, 0.6)
const map_start_in_px = Vector2(580, 0)
const map_scale = 0.0105 # relative to meters

var player_markers = {} # Dictionary of player_id (int) -> Sprite2D
var target_marker = Sprite2D.new()

@onready var map_sprite = get_node_or_null("MapSprite")

func _ready():
	target_marker.texture = load("res://assets/graphics/scena_1/wykrzyknik.svg")
	target_marker.scale = marker_scale
	self.add_child(target_marker)

func set_player(player_id: int, position_t : Vector2, rotation_i, is_local: bool):
	var marker = player_markers.get(player_id)
	if not is_instance_valid(marker):
		marker = Sprite2D.new()
		marker.texture = load("res://assets/graphics/scena_1/Arrow_icon_green.svg")
		if not is_local:
			# Modulate marker to blue for remote players
			marker.modulate = Color(0.2, 0.6, 1.0)
		marker.scale = marker_scale
		self.add_child(marker)
		player_markers[player_id] = marker
	
	var sprite_scale = map_sprite.scale if is_instance_valid(map_sprite) else Vector2(0.65, 0.65)
	
	marker.position = position_t * sprite_scale * map_scale + map_start_in_px
	marker.rotation = rotation_i

func remove_player(player_id: int):
	if player_markers.has(player_id):
		var marker = player_markers[player_id]
		if is_instance_valid(marker):
			marker.queue_free()
		player_markers.erase(player_id)

func set_target(position_t : Vector2 ):
	var sprite_scale = map_sprite.scale if is_instance_valid(map_sprite) else Vector2(0.65, 0.65)
	if is_instance_valid(target_marker):
		target_marker.position = position_t * sprite_scale * map_scale + map_start_in_px

func _input(event):
	if event is InputEventKey and event.keycode == KEY_M:
		self.visible = event.pressed
