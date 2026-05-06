extends Sprite2D

var dragging : bool = false
var last_mouse_position = Vector2.ZERO
const map_view_size = Vector2(960, 540)
var max_position
var min_position
func update_scale():
	max_position = Vector2(texture.get_width() * scale.x / 2, texture.get_height() * scale.y / 2 )
	min_position = Vector2(map_view_size.x - texture.get_width() * scale.x /2 , map_view_size.y - texture.get_height() * scale.y/ 2)
	clamp_position()
func clamp_position():
	position.x = clamp(position.x, min_position.x , max_position.x)
	position.y = clamp(position.y, min_position.y , max_position.y)
func _ready():
	update_scale()

func _input(event) -> void:
	
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_position = event.position
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			scale.x += 0.2
			scale.y += 0.2
			update_scale()	
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			scale.x -= 0.2
			scale.y -= 0.2
			update_scale()
	elif event is InputEventMouseMotion and dragging:
		var delta = ( event.position - last_mouse_position ) * 1
		position += delta
		clamp_position()
		last_mouse_position = event.position
