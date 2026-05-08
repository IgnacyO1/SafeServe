extends CharacterBody2D

var speed = 300.0
var progress_ratio = 0.0

func _physics_process(delta):
	# NPC w tym modelu nie używa move_and_slide, bo jest "na szynach" PathFollow2D.
	# Rodzic (PathFollow2D) zajmuje się ruchem.
	pass

func setup(custom_speed: float, start_offset: float):
	speed = custom_speed
	# Ustawiamy start w losowym miejscu drogi
	get_parent().progress = start_offset
