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
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BURLYWOOD
	multimesh.mesh.surface_set_material(0, mat)
	
	var count = sim.grid_width * sim.grid_height
	multimesh.instance_count = count

func _process(_delta):
	if sim:
		render_grid_3d()

func render_grid_3d():
	var w = sim.grid_width
	var h = sim.grid_height
	var heights : PackedFloat32Array = sim.cell_height

	if heights.size() != w * h:
		return

	var index = 0
	for y in range(h):
		for x in range(w):
			var height = heights[index]
			var t = Transform3D.IDENTITY
			t.origin = Vector3(x, 0, y)
			t = t.scaled(Vector3(1, height, 1))
			multimesh.set_instance_transform(index, t)
			#multimesh.set_instance_color(index, Color.BURLYWOOD)
			index += 1
