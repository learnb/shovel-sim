extends CanvasLayer

@onready var fps_label = $FPS_Label
@onready var stats_label = $Stats_Label
@onready var flow_slider: HSlider = $HSlider_flow
@onready var repose_slider: HSlider = $HSlider_repose
@onready var grid_width_slider: HSlider = $HSlider_grid_width
@onready var grid_height_slider: HSlider = $HSlider_grid_height
@onready var reset_button: Button = $Button
@onready var stop_button: Button = $Button_stop
@export var sim: Node

func _ready():
	fps_label.text = "FPS: 0"
	
	flow_slider.value = sim.FLOW_RATE
	flow_slider.value_changed.connect(_on_flow_rate_change)
	
	repose_slider.value = sim.REPOSE
	repose_slider.value_changed.connect(_on_repose_change)

	grid_width_slider.value = sim.grid_width
	grid_width_slider.value_changed.connect(_on_grid_width_change)
	
	grid_height_slider.value = sim.grid_height
	grid_height_slider.value_changed.connect(_on_grid_height_change)
	
	reset_button.pressed.connect(_on_reset)
	stop_button.pressed.connect(_on_stop)
	
	print(map_value(42, 24, 90, -50, 50))

func map_value(value, in_min, in_max, out_min, out_max):
	var t = inverse_lerp(in_min, in_max, value)
	return lerp(out_min, out_max, t)


func _process(_delta):
	var fps = Engine.get_frames_per_second()
	fps_label.text = "FPS: " + str(fps)
	
	stats_label.text = "Flow_rate: " + str(sim.FLOW_RATE)
	stats_label.text += "\n\nRepose: " + str(sim.REPOSE)

func _on_flow_rate_change(value: float):
	sim.FLOW_RATE = value
	#sim.prepare_buffers()

func _on_repose_change(value: float):
	sim.REPOSE = value
	#sim.prepare_buffers()

func _on_grid_width_change(value: int):
	sim.change_grid_size(value, sim.grid_height)

func _on_grid_height_change(value: int):
	sim.change_grid_size(sim.grid_width, value)

func _on_reset():
	sim.reset()

func _on_stop():
	sim.running = !sim.running
	
	if sim.running:
		stop_button.text = "Stop"
	else:
		stop_button.text = "Start"
