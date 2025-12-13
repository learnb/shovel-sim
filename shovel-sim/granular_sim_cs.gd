extends Node3D

var REPOSE = 0.1   	# stable slope (meters of height difference)
var FLOW_RATE = 0.01	# fraction of excess height to move

var rd: RenderingDevice
var shader_file: RDShaderFile
var shader: RID

var height_buffer: RID
var type_buffer: RID
var uniform_set: RID

var grid_width: int = 128
var grid_height: int = 128
var grid_size: int = grid_width * grid_height
var frame_counter: int = 0
const SYNC_EVERY_N_FRAMES: int = 10

var heights: PackedFloat32Array = PackedFloat32Array()
var types: PackedFloat32Array = PackedFloat32Array()
var output: PackedFloat32Array = PackedFloat32Array()

var multi_mesh_instance: MultiMeshInstance3D
var multi_mesh: MultiMesh

var running: bool = false

func _ready():
	# Create rendering device
	rd = RenderingServer.create_local_rendering_device()

	# Load compute shader
	shader_file = load("res://compute_shader_sim.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)

	# Prepare input data
	init_data()
	prepare_buffers()

	setup_multimesh()

	running = true

func _process(_delta):
	if running:
		run_simulation_step()
		update_multimesh()

func init_data():
	for i in range(grid_size):
		heights.append(randf_range(0.0, 100.0))
		types.append(1)

func update_data():
	heights = output
	#print(heights)

func prepare_buffers():
	var height_bytes: PackedByteArray = heights.to_byte_array()
	var type_bytes: PackedByteArray = types.to_byte_array()

	# Put data into buffers
	height_buffer = rd.storage_buffer_create(height_bytes.size(), height_bytes)
	type_buffer = rd.storage_buffer_create(type_bytes.size(), type_bytes)

	# Create uniforms and assign buffers
	var height_uniform: RDUniform = RDUniform.new()
	height_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	height_uniform.binding = 0
	height_uniform.add_id(height_buffer)

	var type_uniform: RDUniform = RDUniform.new()
	type_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	type_uniform.binding = 1
	type_uniform.add_id(type_buffer)

	uniform_set = rd.uniform_set_create([height_uniform, type_uniform], shader, 0)

func run_simulation_step():
	var x_groups: int = grid_width / 8
	var y_groups: int = grid_height / 8
	var z_groups: int = 1

	# Create compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
	rd.compute_list_end()

	#print("Frame: ", frame_counter)
	# Execute pipeline
	if frame_counter == 0:
		#print("submit")
		rd.submit()

	frame_counter += 1

	# wait a few frames to sync
	if frame_counter >= SYNC_EVERY_N_FRAMES:
		#print("sync")
		rd.sync()
		frame_counter = 0

	# Read results
	if frame_counter == 0:
		#print("read")
		var output_bytes := rd.buffer_get_data(height_buffer)
		output = output_bytes.to_float32_array()
		update_data()

func setup_multimesh():
	multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = BoxMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BURLYWOOD
	multi_mesh.mesh.surface_set_material(0, mat)
	multi_mesh.instance_count = grid_size

	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)

func update_multimesh():
	for x in range(grid_width):
		for y in range(grid_height):
			var index = y * grid_width + x
			var instance_transform = Transform3D()
			instance_transform.origin = Vector3(x, 0, y)
			instance_transform = instance_transform.scaled(Vector3(1, heights[index], 1))
			multi_mesh.set_instance_transform(index, instance_transform)

func _exit_tree():
	# Cleanup all buffers and RIDs
	rd.free_rid(height_buffer)
	rd.free_rid(type_buffer)
	rd.free_rid(uniform_set)
