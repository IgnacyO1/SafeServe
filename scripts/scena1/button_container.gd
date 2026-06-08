extends HFlowContainer

@onready var audio_player : AudioStreamPlayer2D = get_parent().find_child("AudioPlayer")

var emergencies : Array[Emergency]
var button_queue : Array[Button]
var idx : int = 0

func _ready() -> void:
	emergencies.append(Emergency.new("Fire", Vector2(720, 1060) ))
	emergencies[0].add_dialogue_option(DialogueOption.new( "Co się stało?", "res://assets/Sounds/cosięstało.mp3", "Wybuch pożar w jednej z naszych pracowni", "res://assets/Sounds/scena 1/zdarzenie1.mp3", "Przyczyna: Pożar w pracowni"))
	emergencies[0].add_dialogue_option(DialogueOption.new( "Gdzie pan jest?", "res://assets/Sounds/gdziepanjest.mp3", "W Zespole Szkół Łączności, skrzyżowanie Monte Cassino i Kapelanki ", "res://assets/Sounds/scena 1/adres1.mp3", "Adres: ZSŁ nr. 14 Monte Cassino"))
	emergencies[0].add_dialogue_option(DialogueOption.new( "Ile osób jest poszkodowanych?", "res://assets/Sounds/ileosóbjestposzkodowanych.mp3", " Trzech uczniów się poparzyło ", "res://assets/Sounds/scena 1/osoby1.mp3", "Ilość poszkodowanych: 3"))
	
	emergencies.append(Emergency.new("Crime", Vector2(480, 480) ))
	emergencies[1].add_dialogue_option(DialogueOption.new( "Co się stało?", "res://assets/Sounds/cosięstało.mp3", "Jakieś groźne zwierze jest na drzewie, wygląda jak lagun", "res://assets/Sounds/scena 1/zdarzenie2.mp3", "Wydarzenie: Groźne zwierze"))
	emergencies[1].add_dialogue_option(DialogueOption.new( "Gdzie pani jest?", "res://assets/Sounds/gdziepanijest.mp3", "na ulicy Jasnogórskiej", "res://assets/Sounds/scena 1/adres2.mp3", "Adres: ul. Jasnogórska"))
	emergencies[1].add_dialogue_option(DialogueOption.new( "Ile osób jest poszkodowanych?", "res://assets/Sounds/ileosóbjestposzkodowanych.mp3", "Jeszcze nikt, ale to może kogoś pogryźć", "res://assets/Sounds/scena 1/osoby2.mp3", "Ilość poszkodowanych: 0"))

	emergencies.append(Emergency.new("Fire", Vector2(480, 1400) ))
	emergencies[2].add_dialogue_option(DialogueOption.new( "Co się stało?", "res://assets/Sounds/cosięstało.mp3", "Serwerownia nagle zaczęła się palić, nie wygląda to na zwykły pożar", "res://assets/Sounds/scena 1/zdarzenie3.mp3", "Przyczyna: Możliwe podpalenie serwerowni"))
	emergencies[2].add_dialogue_option(DialogueOption.new( "Gdzie pan jest?", "res://assets/Sounds/gdziepanjest.mp3", "Biuro Polyservers, Zielone Tulipany 82 ", "res://assets/Sounds/scena 1/adres3.mp3", "Adres: Zielone Tulipany 82"))
	emergencies[2].add_dialogue_option(DialogueOption.new( "Ile osób jest poszkodowanych?", "res://assets/Sounds/ileosóbjestposzkodowanych.mp3", "Chyba nikt, ale jedna starsza osoba utknęła w budynku", "res://assets/Sounds/scena 1/osoby3.mp3", "Ilość poszkodowanych: 0"))


func begin_call():
	create_buttons(emergencies[idx])
	get_tree().current_scene.emergency = emergencies[idx]
	idx += 1

func create_buttons(emergency : Emergency):
	get_parent().update_transcript("Dzień dobry, 112.")
	audio_player.stream = preload("res://assets/Sounds/112.wav")
	audio_player.play()
	await audio_player.finished
	for opt in emergency.dialogue_options:
		var btn = Button.new()
		btn.text = opt.question
		if "Adres" in opt.information:
			btn.pressed.connect(func(): 
				btn.disabled = true
				option_chosen(opt, emergency.coordinates)
			)
		else:
			btn.pressed.connect(func(): 
				btn.disabled = true
				option_chosen(opt)
			)
		add_child(btn)
	
func say(text : String, dubbing_path : String):
	get_parent().update_transcript(text)
	if dubbing_path != "":
		audio_player.stream = load(dubbing_path)
		audio_player.play()
		await audio_player.finished
	else:
		await get_tree().create_timer(1.0).timeout
		
			
func option_chosen(option : DialogueOption, coordinates = Vector2.ZERO):
	disable_buttons()
	await say(option.question, option.question_voicefile_path)
	await say(option.answer, option.answer_voicefile_path)
	get_parent().information.text += option.information + '\n'
	if coordinates != Vector2.ZERO:
		get_tree().current_scene.map_container.spawn_event(get_tree().current_scene.emergency.type, coordinates)
	if not enable_buttons():
		get_tree().current_scene.side_panel.end_call()
		if idx == emergencies.size():
			get_tree().current_scene.begin_radio_call()
		
func disable_buttons():
	for child in get_children():
		if child.disabled == false:
			child.disabled = true
			button_queue.append(child)

func enable_buttons():
	for child in button_queue:
		child.disabled = false
	if button_queue.size() == 0:
		return false
	button_queue.clear()
	return true
