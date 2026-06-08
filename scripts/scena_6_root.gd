extends "res://scripts/radio.gd"
var greg_say_count : int = 1

const responses : Array[String] = [
]
const responses_voice_paths : Array[String] = [

]
func request_message():
	radio_sprite.clickable = true
	while radio_sprite.clickable:
		pass
	return
	
func _ready() -> void:
	await get_tree().create_timer(3.0).timeout
	await radio.show_radio_message("Greg, zgłoś się, żyjesz?",	"res://assets/Sounds/metro1.mp3")
	glow.start_glow()
	
	radio_sprite.clickable = true

func _process(_delta: float) -> void:
	if greg_say_count == 2:
		greg_say_count += 1
		await radio.show_radio_message("Greg, w sektorze A5. Dobrze, że jesteś tam na dole. Pilnie cie potrzebujemy - został porwany pociąg metra. Idź do centrum sterowania i spróbuj go zatrzymać. ",	"res://assets/Sounds/metro2.mp3",	)
		glow.start_glow()
		radio_sprite.clickable = true
		
		
