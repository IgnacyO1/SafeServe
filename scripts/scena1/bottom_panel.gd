extends Panel
class_name Scena1BottomPanel 
@onready var information = $"Information"
@onready var icon = $"Icon"
@onready var transcript = $"ScrollContainer/Transcript"
@onready var button_container = $"ButtonContainer"
@onready var side_panel = get_tree().current_scene.side_panel
var call_in_progress : bool = false
var counter : float = 0
var target : int = 0
func display_event(event : MapEvent):
	#const localization : Dictionary = {
		#"Fire" : "Ogień",
		#"Emergency" : "Wypadek",
		#"Crime" : "Przestępstwo"
	#}
	#information.text = localization[event.type]
	icon.texture = event.marker.texture_normal

func clear():
	information.text = ""
	icon.texture = null
	transcript.text = ""
	for child in button_container.get_children():    
		button_container.remove_child(child)    
		child.queue_free()
	
	
func update_transcript(text : String):
	transcript.text += '- ' + text + '\n'
	transcript.get_parent().scroll_vertical = transcript.get_parent().get_v_scroll_bar().max_value

func _process(delta: float) -> void:
	if not call_in_progress:
		if target == 0:
			target = randi_range(3, 5)
			counter = 0
		counter += delta
		if counter > target:
			button_container.begin_call()
			target = 0
			call_in_progress = true
