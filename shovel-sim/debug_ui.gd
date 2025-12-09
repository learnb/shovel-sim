extends CanvasLayer

@onready var fps_label = $FPS_Label
@onready var stats_label = $Stats_Label
@onready var flow_slider: HSlider = $HSlider_flow
@onready var repose_slider: HSlider = $HSlider_repose
@onready var reset_button: Button = $Button
@export var sim: Node

func _ready():
	fps_label.text = "FPS: 0"
	
	flow_slider.value = sim.FLOW_RATE
	flow_slider.value_changed.connect(_on_flow_rate_change)
	
	repose_slider.value = sim.REPOSE
	repose_slider.value_changed.connect(_on_repose_change)
	
	reset_button.pressed.connect(_on_reset)

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	fps_label.text = "FPS: " + str(fps)
	
	stats_label.text = "Flow_rate: " + str(sim.FLOW_RATE)
	stats_label.text += "\n\nRepose: " + str(sim.REPOSE)

func _on_flow_rate_change(value: float):
	sim.FLOW_RATE = value

func _on_repose_change(value: float):
	sim.REPOSE = value

func _on_reset():
	sim.reset()
