extends MultiMeshInstance3D

@export var sim : Node

func _ready():
	setup_multimesh()

func setup_multimesh():
	if sim == null:
		push_error("grid_render has no sim reference")
		return
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	
	var count = sim.grid_width * sim.grid_height
	multimesh.instance_count = count

func _process(_delta):
	if sim:
		render_grid_3d()

func render_grid_3d():
	var w = sim.grid_width
	var h = sim.grid_height
	var heights : PackedFloat32Array = sim.cell_height

	# safety if sizes mismatch
	if heights.size() != w * h:
		return

	var index = 0
	for y in range(h):
		for x in range(w):
			var height = heights[index]
			var t = Transform3D.IDENTITY
			t.origin = Vector3(x, height, y)
			multimesh.set_instance_transform(index, t)
			index += 1
