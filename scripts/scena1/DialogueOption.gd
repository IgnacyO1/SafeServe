class_name DialogueOption

var question : String
var question_voicefile_path : String
var answer : String
var answer_voicefile_path : String
var information : String

func _init( question_i : String, question_voicefile_path_i : String, answer_i : String, answer_voicefile_path_i : String, information_i : String) -> void:
	question = question_i
	question_voicefile_path = question_voicefile_path_i
	answer = answer_i
	answer_voicefile_path = answer_voicefile_path_i
	information = information_i
	
