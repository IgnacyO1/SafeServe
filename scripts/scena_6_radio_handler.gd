extends TextureButton

var root
var radio = null
var clickable : bool = true

func _ready() -> void:
	root = get_tree().current_scene
	

var idx : int = 0 
const greg_messages : Array[String] = [
	"Tak, tak, zgłaszam się, jestem na dole",
	"OK, przyjąłem",
	
]
const greg_voice_paths : Array[String] = [
	"res://assets/Sounds/metroodp1.mp3",
	"res://assets/Sounds/metroodp2.mp3",

]

func play_next_sequence():
	if greg_messages.size() <= idx: 
		print("Ran out of messages!")
		return
	#await get_tree().current_scene.radio.show_radio_message(responses[idx], responses_voice_paths[idx], false)
	await get_tree().current_scene.radio.show_radio_message(greg_messages[idx], greg_voice_paths[idx], true)
	idx += 1
	get_tree().current_scene.greg_say_count += 1

func _click():
	if not clickable:
		return
	if not radio:
		radio = root.radio
	clickable = false
	get_tree().current_scene.glow.stop_glow()
	play_next_sequence()
	

	
