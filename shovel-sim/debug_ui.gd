extends CanvasLayer

@onready var fps_label = $FPS_Label

func _ready():
	fps_label.text = "FPS: 0"

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	fps_label.text = "FPS: " + str(fps)
