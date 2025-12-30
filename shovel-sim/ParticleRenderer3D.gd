extends MultiMeshInstance3D
class_name ParticleRenderer3D

@export var simulation: ParticleSimulation3D

var particle_mesh: BoxMesh

func _ready():
	if not simulation:
		push_error("ParticleRenderer3D requires a simulation reference!")
		return
	
	_setup_multimesh()

func _setup_multimesh():
	"""Initialize MultiMesh for instanced particle rendering"""
	# Create a small cube mesh for each particle
	particle_mesh = BoxMesh.new()
	particle_mesh.size = Vector3.ONE * simulation.voxel_size * 0.8  # Slightly smaller than voxel
	
	# Create MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true  # Enable per-instance colors
	multimesh.instance_count = simulation.get_total_voxel_count()
	multimesh.mesh = particle_mesh
	
	# Initially hide all instances (we'll update this each frame)
	for i in range(multimesh.instance_count):
		multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -1000, 0)))  # Hide offscreen
	
	print("ParticleRenderer3D initialized with %d instances" % multimesh.instance_count)

func _process(_delta):
	if simulation and simulation.current_read_images.size() > 0:
		_update_particle_instances()

func _update_particle_instances():
	"""Update MultiMesh instances based on current particle state"""
	var instance_index = 0
	var visible_count = 0
	
	for z in range(simulation.grid_resolution.z):
		var layer_image = simulation.current_read_images[z]
		
		for y in range(simulation.grid_resolution.y):
			for x in range(simulation.grid_resolution.x):
				var pixel = layer_image.get_pixel(x, y)
				var material_type = int(pixel.r * 255.0)
				
				if material_type > 0:
					# Particle exists - position it and color it
					var grid_pos = Vector3i(x, y, z)
					var world_pos = simulation.grid_to_world(grid_pos)
					
					var transform = Transform3D(Basis(), world_pos)
					multimesh.set_instance_transform(instance_index, transform)
					
					# Set color based on material type
					var color = simulation.get_material_color(material_type)
					multimesh.set_instance_color(instance_index, color)
					visible_count += 1
				else:
					# No particle - hide this instance
					multimesh.set_instance_transform(instance_index, Transform3D(Basis(), Vector3(0, -1000, 0)))
				
				instance_index += 1
	
	# Debug: print visible count occasionally
	if Engine.get_frames_drawn() % 60 == 0 and visible_count > 0:
		print("Rendering %d visible particles" % visible_count)
