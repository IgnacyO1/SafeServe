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
	"Fire" : "orange",
	"Police" : "blue",
	"Fire rescue" : "dark_red",
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
var Events : Array[MapEvent]


func spawn_event(type : String):
	Events.push_back(
	MapEvent.new(self,
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
	
