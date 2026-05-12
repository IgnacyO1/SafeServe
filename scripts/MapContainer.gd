extends Node2D
class_name MapContainer

var any_emergencies = false

const scroll_factor : float = 0.05
const map_margin : Vector2 = Vector2(250, 150)

const event_type_to_marker_filename : Dictionary = {
	"Fire" : "ogien.png",
	"Police" : "police.svg",
	"Fire rescue" : "fire_truck.svg",
	"Ambulance" : "ambulance.svg",
	"Emergency" : "wykrzyknik.svg",
	"Crime" : "zlodziej.svg"
}
const event_type_to_arrow_color : Dictionary = {
	"Fire" : "red",
	"Police" : "blue",
	"Fire rescue" : "blue",
	"Ambulance" : "white",
	"Emergency" : "red",
	"Crime" : "black"
}
func find_marker_filename(type : String ):
	return "res://assets/graphics/" + event_type_to_marker_filename[type] 

func find_arrow_filename(type : String ):
	return "res://assets/graphics/" + "Arrow_icon_" + event_type_to_arrow_color[type] + ".svg"

var map_view_size
var MapSprite : Sprite2D
var Events : Array[Map_Event]

class Map_Event:
	var id : int
	var container_node : MapContainer
	var marker : TextureButton
	var arrow_sprite : TextureButton
	var type : String
	func on_press():
		container_node.get_tree().current_scene.message(self)
	func _init(container_node_i : MapContainer, marker_texture : Texture2D, arrow_texture : Texture2D, type_i : String):
		id = randi()
		type = type_i
		container_node = container_node_i
		marker = TextureButton.new()
		marker.texture_normal = marker_texture
		@warning_ignore("integer_division", "narrowing_conversion")
		marker.position.x = randi_range(marker_texture.get_width() / 2 + map_margin.x, container_node.MapSprite.texture.get_size().x * container_node.MapSprite.scale.x - marker_texture.get_width() / 2 - map_margin.x)
		@warning_ignore("integer_division", "narrowing_conversion")
		marker.position.y = randi_range(marker_texture.get_height() / 2 + map_margin.y, container_node.MapSprite.texture.get_size().y * container_node.MapSprite.scale.y - marker_texture.get_height() / 2 - map_margin.y)
		marker.pressed.connect(on_press)
		marker.name = type + " Icon"

		arrow_sprite = TextureButton.new()
		arrow_sprite.texture_normal = arrow_texture
		arrow_sprite.name = type + " Arrow"
		
		container_node.add_child(marker)
		container_node.add_child(arrow_sprite)
		
	func update_arrow():
		arrow_sprite.visible = true
		var viewport_center : Vector2 = -1 * container_node.position + container_node.map_view_size / 2.0
		var vector : Vector2 = marker.position - viewport_center
		if absf(vector.x) < container_node.map_view_size.x / 2.0 and absf(vector.y) < container_node.map_view_size.y / 2.0:
			arrow_sprite.visible = false
		var vector_angle : float = atan(vector.y / vector.x)
		var vector_scale : float 
		if absf(vector.x / container_node.map_view_size.x) < absf(vector.y / container_node.map_view_size.y):
			vector_scale = ( container_node.map_view_size.y - map_margin.y )/ 2.0 / absf(vector.y)
		else:
			vector_scale = ( container_node.map_view_size.x - map_margin.x ) / 2.0 / absf(vector.x)

		if vector.x < 0:
			vector_angle = vector_angle - PI
		arrow_sprite.rotation = vector_angle
		arrow_sprite.position =  vector * vector_scale + viewport_center

	func scale_marker(amount : float):
		var original_scale = container_node.MapSprite.scale.x
		marker.position *= ((original_scale + amount) / original_scale)
	func delete():
		container_node.Events.remove_at(container_node.Events.rfind(self))
		container_node.any_emergencies = false
		for e in container_node.Events:
			if e.type in ["Crime", "Emergency", "Fire"]:
				container_node.any_emergencies = true
				break
		marker.queue_free()
		arrow_sprite.queue_free()

func spawn_event(type : String):
	Events.push_back(
	Map_Event.new(self,
	load(find_marker_filename(type)), 
	load(find_arrow_filename(type)),
	type)) 
	if type in ["Crime", "Emergency", "Fire"]:
		any_emergencies = true

	
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
	
