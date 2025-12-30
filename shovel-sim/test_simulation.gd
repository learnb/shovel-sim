extends Node3D

@onready var simulation: ParticleSimulation3D = $ParticleSimulation3D
@onready var camera: Camera3D = $Camera3D

func _ready():
	test_coordinate_conversion()
	test_material_properties()
	test_texture_buffers()
	
	# Setup camera to look at the center of the grid
	setup_camera()
	
	# Wait a frame for everything to initialize, then spawn test particles
	await get_tree().process_frame
	spawn_test_particles()
	
	# Print some debug info every second
	var timer = Timer.new()
	timer.timeout.connect(_print_debug_info)
	timer.wait_time = 1.0
	add_child(timer)
	timer.start()

func setup_camera():
	if camera:
		var bounds = simulation.get_grid_world_bounds()
		var center = bounds.position + bounds.size * 0.5
		
		# Position camera to look at grid center from an angle
		camera.position = center + Vector3(5, 5, 5)
		camera.look_at(center)
		
		print("\n=== Camera Setup ===")
		print("Grid center: %s" % center)
		print("Camera position: %s" % camera.position)
	
	# Add a reference plane at the bottom of the grid
	_add_reference_plane()

func _add_reference_plane():
	"""Add a ground plane for visual reference"""
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(10, 10)
	mesh_instance.mesh = plane_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	mesh_instance.set_surface_override_material(0, material)
	
	# Position at grid origin
	mesh_instance.position = Vector3(5, 0, 5)
	add_child(mesh_instance)

func _print_debug_info():
	print("\n=== Debug Info ===")
	print("Simulation running: %s" % simulation.simulate)
	
	# Count active particles
	var particle_count = 0
	for z in range(simulation.grid_resolution.z):
		var layer = simulation.current_read_images[z]
		for y in range(simulation.grid_resolution.y):
			for x in range(simulation.grid_resolution.x):
				var pixel = layer.get_pixel(x, y)
				if int(pixel.r * 255.0) > 0:
					particle_count += 1
	
	print("Active particles: %d" % particle_count)

func spawn_test_particles():
	print("\n=== Spawning Test Particles ===")
	
	# Spawn a column of sand particles in the middle of the grid
	var center = Vector3i(
		simulation.grid_resolution.x / 2,
		simulation.grid_resolution.y / 2,
		simulation.grid_resolution.z / 2
	)
	
	print("Spawning sand column at grid position: %s" % center)
	simulation.spawn_particle_column(center, 10, ParticleSimulation3D.MaterialType.SAND)
	
	# Spawn a small box of dirt particles
	var box_min = Vector3i(center.x - 2, center.y - 5, center.z - 2)
	var box_max = Vector3i(center.x + 2, center.y - 5, center.z + 2)
	print("Spawning dirt box from %s to %s" % [box_min, box_max])
	simulation.spawn_particle_box(box_min, box_max, ParticleSimulation3D.MaterialType.DIRT)
	
	print("Test particles spawned! Simulation should start updating...")

func test_coordinate_conversion():
	print("\n=== Testing Coordinate Conversion ===")
	
	# Test world to grid
	var world_pos = Vector3(0.5, 0.5, 0.5)
	var grid_pos = simulation.world_to_grid(world_pos)
	print("World %s -> Grid %s" % [world_pos, grid_pos])
	
	# Test grid to world
	var back_to_world = simulation.grid_to_world(grid_pos)
	print("Grid %s -> World %s" % [grid_pos, back_to_world])
	
	# Test bounds checking
	print("Is (0,0,0) valid? %s" % simulation.is_valid_grid_position(Vector3i(0, 0, 0)))
	print("Is (100,100,100) valid? %s" % simulation.is_valid_grid_position(Vector3i(100, 100, 100)))
	print("Is (-1,0,0) valid? %s" % simulation.is_valid_grid_position(Vector3i(-1, 0, 0)))
	
	# Test grid bounds
	var bounds = simulation.get_grid_world_bounds()
	print("Grid world bounds: Position=%s, Size=%s" % [bounds.position, bounds.size])

func test_material_properties():
	print("\n=== Testing Material Properties ===")
	
	for material_type in [
		ParticleSimulation3D.MaterialType.SAND,
		ParticleSimulation3D.MaterialType.DIRT,
		ParticleSimulation3D.MaterialType.MULCH
	]:
		var type_name = ParticleSimulation3D.MaterialType.keys()[material_type]
		var color = simulation.get_material_color(material_type)
		var density = simulation.get_material_property(material_type, "density")
		var angle = simulation.get_material_property(material_type, "angle_of_repose")
		
		print("%s: color=%s, density=%.1f, angle=%.1f°" % [type_name, color, density, angle])

func test_texture_buffers():
	print("\n=== Testing Texture Buffers ===")
	
	print("Current read buffer: %s" % simulation.current_read_buffer)
	print("Current write buffer: %s" % simulation.current_write_buffer)
	
	# Test buffer swap
	var original_read = simulation.current_read_buffer
	var original_write = simulation.current_write_buffer
	
	simulation.swap_buffers()
	
	print("After swap:")
	print("  Read buffer changed: %s" % (simulation.current_read_buffer != original_read))
	print("  Write buffer changed: %s" % (simulation.current_write_buffer != original_write))
	print("  Buffers swapped correctly: %s" % (simulation.current_read_buffer == original_write))

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("\n=== Manual Test Trigger ===")
			test_coordinate_conversion()
		elif event.keycode == KEY_R:
			print("\n=== Reloading Simulation ===")
			get_tree().reload_current_scene()
		elif event.keycode == KEY_S:
			print("\n=== Toggling Simulation ===")
			simulation.simulate = !simulation.simulate
			print("Simulation: %s" % ("RUNNING" if simulation.simulate else "PAUSED"))
		elif event.keycode == KEY_P:
			print("\n=== Spawning More Particles ===")
			spawn_test_particles()
