extends Node2D

const scroll_factor : float = 0.05
const arrow_margin : float = 100

var map_view_size
var MapSprite : Sprite2D
var Events : Array[Map_Event]

class Map_Event:
	var container_node : Node2D
	var marker_sprite : Sprite2D
	var arrow_sprite : Sprite2D
	func _init(container_node_i : Node2D, marker_texture : Texture2D, arrow_texture : Texture2D):
		container_node = container_node_i
		marker_sprite = Sprite2D.new()
		marker_sprite.texture = marker_texture
		@warning_ignore("integer_division", "narrowing_conversion")
		marker_sprite.position = Vector2i(randi_range(marker_texture.get_width() / 2, container_node.MapSprite.texture.get_size().x - marker_texture.get_width() / 2.0 ), randi_range(marker_texture.get_height() / 2.0, container_node.MapSprite.texture.get_size().y - marker_texture.get_height() / 2.0 ) )
		marker_sprite.name = "EmergencyIcon"

		arrow_sprite = Sprite2D.new()
		arrow_sprite.texture = arrow_texture
		arrow_sprite.name = "EmergencyIconArrow"
		
		container_node.add_child(marker_sprite)
		container_node.add_child(arrow_sprite)
		
	func update_arrow():
		arrow_sprite.visible = true
		var viewport_center : Vector2 = -1 * container_node.position + container_node.map_view_size / 2.0
		var vector : Vector2 = marker_sprite.position - viewport_center
		if absf(vector.x) < container_node.map_view_size.x / 2.0 and absf(vector.y) < container_node.map_view_size.y / 2.0:
			arrow_sprite.visible = false
		var vector_angle : float = atan(vector.y / vector.x)
		var vector_scale : float 
		if absf(vector.x / 16.0) < absf(vector.y / 9.0):
			vector_scale = ( container_node.map_view_size.y - arrow_margin )/ 2.0 / absf(vector.y)
		else:
			vector_scale = ( container_node.map_view_size.x - arrow_margin ) / 2.0 / absf(vector.x)

		if vector.x < 0:
			vector_angle = vector_angle - PI
		arrow_sprite.rotation = vector_angle
		arrow_sprite.position =  vector * vector_scale + viewport_center

	func scale_marker(amount : float):
		var original_scale = container_node.MapSprite.scale.x
		marker_sprite.position *= ((original_scale + amount) / original_scale)

func update_scale(amount : float):
	if (MapSprite.texture.get_width() * (MapSprite.scale.x + amount ) < map_view_size.x ) or (MapSprite.texture.get_height() * (MapSprite.scale.y + amount ) < map_view_size.y ):
			return
	for i in range(Events.size()):
		Events[i].scale_marker(amount)

	MapSprite.scale += Vector2(amount, amount)
	MapSprite.position = Vector2(MapSprite.texture.get_width() * MapSprite.scale.x / 2, MapSprite.texture.get_height() * MapSprite.scale.y / 2)

	max_position = Vector2.ZERO
	min_position = Vector2(map_view_size.x - MapSprite.texture.get_width() * MapSprite.scale.x, map_view_size.y - MapSprite.texture.get_height() * MapSprite.scale.y)
	
	clamp_position()

var max_position : Vector2
var min_position : Vector2
func clamp_position():
	position.x = clamp(position.x, min_position.x , max_position.x)
	position.y = clamp(position.y, min_position.y , max_position.y)

func _ready():
	map_view_size = Vector2(self.get_parent().get_parent().size)
	MapSprite = self.find_child("MapSprite")
	Events.push_back(Map_Event.new(self, load("res://assets/graphics/ogien.png"), load("res://assets/graphics/Arrow_Icon.svg")))

	update_scale(0) # Initialize a few things
	
func _process(_delta : float):
	for i in range(Events.size()):
		Events[i].update_arrow()

var map_locked : bool = false
var dragging : bool = false
var last_mouse_position : Vector2 = Vector2.ZERO
func _input(event) -> void:
	if event is InputEventMouseButton and not map_locked:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_position = event.position
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			update_scale(scroll_factor)
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			update_scale(-scroll_factor)
	elif event is InputEventMouseMotion and dragging and not map_locked:
		var delta = ( event.position - last_mouse_position ) * 1
		position += delta
		clamp_position()
		last_mouse_position = event.position
	
