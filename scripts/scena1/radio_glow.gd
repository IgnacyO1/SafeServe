extends Sprite2D

var glow : bool = false
var counter : float = 0
const rate : float = 0.5

func _process(delta):
	if glow:
		counter += delta
		if counter > rate:
			visible = not visible
			counter = 0

func start_glow():
	glow = true
	visible = true

func stop_glow():
	glow = false
	visible = false
