extends Node3D

@onready var simulation: ParticleSimulation3D = $ParticleSimulation3D

func _ready():
	test_coordinate_conversion()
	test_material_properties()
	test_texture_buffers()

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
