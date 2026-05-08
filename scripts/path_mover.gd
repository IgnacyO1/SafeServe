# path_mover.gd
extends Node

var speed = 200.0
@onready var parent = get_parent() # To będzie PathFollow2D

func _process(delta):
	if parent is PathFollow2D:
		parent.progress += speed * delta
