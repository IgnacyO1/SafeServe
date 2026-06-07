class_name MapEvent
var id : int
var container_node : MapContainer
var marker : TextureButton
var arrow_sprite : TextureButton
var type : String
var map_margin 
func on_press():
	container_node.get_tree().current_scene.message(self)
func _init(container_node_i : MapContainer, marker_texture : Texture2D, arrow_texture : Texture2D, type_i : String, position_i : Vector2):
	id = randi()
	type = type_i
	container_node = container_node_i
	marker = TextureButton.new()
	marker.texture_normal = marker_texture
	map_margin = container_node.map_margin
	if position_i ==  Vector2(-1, -1):
		@warning_ignore("integer_division", "narrowing_conversion")
		marker.position.x = randi_range(
			marker_texture.get_width() / 2 + map_margin.x,
			container_node.MapSprite.texture.get_size().x * container_node.MapSprite.scale.x - marker_texture.get_width() / 2 - map_margin.x
		)
		@warning_ignore("integer_division", "narrowing_conversion")
		marker.position.y = randi_range(
			marker_texture.get_height() / 2 + map_margin.y,
			container_node.MapSprite.texture.get_size().y * container_node.MapSprite.scale.y - marker_texture.get_height() / 2 - map_margin.y
		)
	else: 
		marker.position = Vector2(
			position_i.x * container_node.MapSprite.scale.x,
			position_i.y * container_node.MapSprite.scale.y
		)
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
	marker.queue_free()
	arrow_sprite.queue_free()
