extends Node2D

const scroll_factor : float = 0.05

var map_view_size
var map_locked : bool = false
var dragging : bool = false
var last_mouse_position : Vector2 = Vector2.ZERO
var max_position : Vector2
var min_position : Vector2
var MapSprite : Sprite2D

var EmergencySprite : Sprite2D
var ArrowSprite : Sprite2D


func spawn_marker(texture_i : Texture2D, map_size : Vector2) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture_i
	sprite.position = Vector2(randi_range(sprite.texture.get_width() / 2, map_size.x - sprite.texture.get_width() / 2 ), randi_range(sprite.texture.get_height() / 2, map_size.y - sprite.texture.get_height() / 2 ) )
	sprite.name = "EmergencyIcon"
	return sprite

func spawn_arrow(texture_i : Texture2D) -> Sprite2D:
	var arrow = Sprite2D.new()
	arrow.texture = texture_i
	arrow.name = "EmergencyIconArrow"
	return arrow

func update_arrow(arrow_sprite : Sprite2D, marker_sprite : Sprite2D):
	arrow_sprite.visible = true
	var viewport_center : Vector2 = -1 * position + map_view_size / 2.0
	var vector : Vector2 = marker_sprite.position - viewport_center
	if absf(vector.x) < map_view_size.x / 2.0 and absf(vector.y) < map_view_size.y / 2.0:
		arrow_sprite.visible = false
	var vector_angle : float = atan(vector.y / vector.x)
	var vector_scale : float 
	const arrow_margin : float = 100
	if absf(vector.x / 16.0) < absf(vector.y / 9.0):
		vector_scale = ( map_view_size.y - arrow_margin )/ 2.0 / absf(vector.y)
	else:
		vector_scale = ( map_view_size.x - arrow_margin ) / 2.0 / absf(vector.x)

	if vector.x < 0:
		vector_angle = vector_angle - PI
	arrow_sprite.rotation = vector_angle
	arrow_sprite.position =  vector * vector_scale + viewport_center

func update_scale(amount : float):
	if (MapSprite.texture.get_width() * (MapSprite.scale.x + amount ) < map_view_size.x ) or (MapSprite.texture.get_height() * (MapSprite.scale.y + amount ) < map_view_size.y ):
			return
	EmergencySprite.position *= ((MapSprite.scale.x + amount) / MapSprite.scale.x )

	MapSprite.scale += Vector2(amount, amount)
	MapSprite.position = Vector2(MapSprite.texture.get_width() * MapSprite.scale.x / 2, MapSprite.texture.get_height() * MapSprite.scale.y / 2)

	max_position = Vector2.ZERO
	min_position = Vector2(map_view_size.x - MapSprite.texture.get_width() * MapSprite.scale.x, map_view_size.y - MapSprite.texture.get_height() * MapSprite.scale.y)
	
	clamp_position()

func clamp_position():
	position.x = clamp(position.x, min_position.x , max_position.x)
	position.y = clamp(position.y, min_position.y , max_position.y)

func _ready():
	map_view_size = Vector2(self.get_parent().get_parent().size)
	MapSprite = self.find_child("MapSprite")
	
	EmergencySprite = spawn_marker(load("res://assets/graphics/ogien.png") , MapSprite.texture.get_size() * MapSprite.scale)
	self.add_child(EmergencySprite)
	ArrowSprite = spawn_arrow(load("res://assets/graphics/Arrow_Icon.svg"))
	self.add_child(ArrowSprite)
	

	
	update_scale(0) # Initialize a few things
	
func _process(_delta : float):
	update_arrow(ArrowSprite, EmergencySprite)


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
	
