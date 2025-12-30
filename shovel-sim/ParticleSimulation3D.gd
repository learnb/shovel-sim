extends Node3D
class_name ParticleSimulation3D

## Grid Configuration
@export_group("Grid Settings")
@export var grid_resolution := Vector3i(64, 64, 64)
@export var voxel_size := 0.1  # Size of each voxel in world units
@export var grid_origin := Vector3.ZERO  # World-space origin of the grid

## Material Types
enum MaterialType {
	EMPTY = 0,
	SAND = 1,
	DIRT = 2,
	MULCH = 3,
	GRAVEL = 4
}

## Material Properties
class MaterialProperties:
	var density: float
	var friction: float
	var angle_of_repose: float  # In degrees
	var cohesion: float
	var flow_rate: float
	var color: Color
	
	func _init(p_density: float, p_friction: float, p_angle: float, p_cohesion: float, p_flow: float, p_color: Color):
		density = p_density
		friction = p_friction
		angle_of_repose = p_angle
		cohesion = p_cohesion
		flow_rate = p_flow
		color = p_color

## Texture Buffers (ping-pong)
var particle_texture_a: Texture2DArray
var particle_texture_b: Texture2DArray
var current_read_buffer: Texture2DArray
var current_write_buffer: Texture2DArray

# Image data backing the textures (we modify these, then rebuild textures)
var images_a: Array[Image] = []
var images_b: Array[Image] = []
var current_read_images: Array[Image]
var current_write_images: Array[Image]

## Shader Pipeline
var physics_shader: Shader
var physics_material: ShaderMaterial
var sub_viewports: Array[SubViewport] = []  # One per layer
var color_rects: Array[ColorRect] = []  # One per layer for rendering
var viewport_textures: Array[ViewportTexture] = []  # Capture results

## Simulation State
@export var simulate: bool = true
@export var gravity := Vector3(0.0, -9.8, 0.0)

## Material lookup
var material_properties: Dictionary = {}

func _ready():
	_initialize_material_properties()
	_initialize_texture_buffers()
	_initialize_shader_pipeline()
	print("ParticleSimulation3D initialized")
	print("Grid resolution: %s" % grid_resolution)
	print("Grid world bounds: %s" % get_grid_world_bounds())
	print("Total voxels: %d" % get_total_voxel_count())

func _initialize_material_properties():
	"""Define properties for each material type"""
	# Format: density, friction, angle_of_repose, cohesion, flow_rate, color
	material_properties[MaterialType.EMPTY] = MaterialProperties.new(
		0.0, 0.0, 0.0, 0.0, 0.0, Color.TRANSPARENT
	)
	
	material_properties[MaterialType.SAND] = MaterialProperties.new(
		1.6, 0.5, 34.0, 0.1, 0.8, Color(0.76, 0.70, 0.50)  # Tan/beige
	)
	
	material_properties[MaterialType.DIRT] = MaterialProperties.new(
		1.3, 0.7, 40.0, 0.3, 0.5, Color(0.35, 0.25, 0.15)  # Brown
	)
	
	material_properties[MaterialType.MULCH] = MaterialProperties.new(
		0.4, 0.8, 45.0, 0.5, 0.3, Color(0.20, 0.12, 0.08)  # Dark brown
	)
	
	material_properties[MaterialType.GRAVEL] = MaterialProperties.new(
		1.8, 0.6, 38.0, 0.0, 0.7, Color(0.5, 0.5, 0.5)  # Gray
	)

func _initialize_texture_buffers():
	"""Create ping-pong texture buffers for particle data"""
	var layers = grid_resolution.z
	var width = grid_resolution.x
	var height = grid_resolution.y
	
	# Create empty image data for all layers (both buffers)
	for z in range(layers):
		var img_a = Image.create(width, height, false, Image.FORMAT_RGBA8)
		var img_b = Image.create(width, height, false, Image.FORMAT_RGBA8)
		img_a.fill(Color(0, 0, 0, 0))  # Empty particles
		img_b.fill(Color(0, 0, 0, 0))
		images_a.append(img_a)
		images_b.append(img_b)
	
	# Create Texture2DArray A
	particle_texture_a = Texture2DArray.new()
	particle_texture_a.create_from_images(images_a)
	
	# Create Texture2DArray B
	particle_texture_b = Texture2DArray.new()
	particle_texture_b.create_from_images(images_b)
	
	# Set initial read/write buffers
	current_read_buffer = particle_texture_a
	current_write_buffer = particle_texture_b
	current_read_images = images_a
	current_write_images = images_b

func swap_buffers():
	"""Swap read and write buffers for next frame"""
	var temp_tex = current_read_buffer
	var temp_img = current_read_images
	
	current_read_buffer = current_write_buffer
	current_read_images = current_write_images
	
	current_write_buffer = temp_tex
	current_write_images = temp_img

func _initialize_shader_pipeline():
	"""Set up SubViewports for processing each particle layer"""
	# Load physics shader
	physics_shader = load("res://particle_physics.gdshader")
	if physics_shader == null:
		push_error("Failed to load particle_physics.gdshader")
		return
	
	# Create a SubViewport + ColorRect for EACH layer
	# This allows us to process each Z-slice independently
	for z in range(grid_resolution.z):
		# Create viewport
		var viewport = SubViewport.new()
		viewport.size = Vector2i(grid_resolution.x, grid_resolution.y)
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		viewport.transparent_bg = false
		add_child(viewport)
		sub_viewports.append(viewport)
		
		# Create shader material for this layer
		var material = ShaderMaterial.new()
		material.shader = physics_shader
		
		# Create ColorRect to render the shader
		var rect = ColorRect.new()
		rect.size = Vector2(grid_resolution.x, grid_resolution.y)
		rect.material = material
		viewport.add_child(rect)
		color_rects.append(rect)
		
		# Get viewport texture for reading back
		viewport_textures.append(viewport.get_texture())
	
	print("Shader pipeline initialized with %d layer viewports" % sub_viewports.size())

## Coordinate Conversion Functions

func world_to_grid(world_pos: Vector3) -> Vector3i:
	"""Convert world-space position to grid coordinates"""
	var relative = world_pos - grid_origin
	var grid_pos = relative / voxel_size
	return Vector3i(
		int(floor(grid_pos.x)),
		int(floor(grid_pos.y)),
		int(floor(grid_pos.z))
	)

func grid_to_world(grid_pos: Vector3i) -> Vector3:
	"""Convert grid coordinates to world-space position (center of voxel)"""
	var world_pos = Vector3(grid_pos) * voxel_size + grid_origin
	world_pos += Vector3.ONE * voxel_size * 0.5  # Center of voxel
	return world_pos

func is_valid_grid_position(grid_pos: Vector3i) -> bool:
	"""Check if grid coordinates are within bounds"""
	return (grid_pos.x >= 0 and grid_pos.x < grid_resolution.x and
			grid_pos.y >= 0 and grid_pos.y < grid_resolution.y and
			grid_pos.z >= 0 and grid_pos.z < grid_resolution.z)

func get_grid_world_bounds() -> AABB:
	"""Get the world-space bounding box of the grid"""
	var size = Vector3(grid_resolution) * voxel_size
	return AABB(grid_origin, size)

func get_total_voxel_count() -> int:
	"""Get total number of voxels in grid"""
	return grid_resolution.x * grid_resolution.y * grid_resolution.z

## Material Access Functions

func get_material_color(material_type: MaterialType) -> Color:
	"""Get the color for a material type"""
	if material_type in material_properties:
		return material_properties[material_type].color
	return Color.MAGENTA  # Error color

func get_material_property(material_type: MaterialType, property: String) -> float:
	"""Get a specific property value for a material type"""
	if material_type in material_properties:
		var props = material_properties[material_type]
		match property:
			"density": return props.density
			"friction": return props.friction
			"angle_of_repose": return props.angle_of_repose
			"cohesion": return props.cohesion
			"flow_rate": return props.flow_rate
	return 0.0

## Particle Spawning Functions

func spawn_particle_at_grid(grid_pos: Vector3i, material_type: MaterialType, velocity: Vector3 = Vector3.ZERO):
	"""Spawn a single particle at a grid position"""
	if not is_valid_grid_position(grid_pos):
		push_warning("Attempted to spawn particle at invalid grid position: %s" % grid_pos)
		return
	
	# Get the image for this Z layer from write buffer
	var layer = grid_pos.z
	var image = current_write_images[layer]
	
	# Encode particle data
	var color = Color()
	color.r = float(material_type) / 255.0
	# Encode velocity (-2 to +2 m/s range to 0-1)
	color.g = clamp(velocity.x / 4.0 + 0.5, 0.0, 1.0)
	color.b = clamp(velocity.y / 4.0 + 0.5, 0.0, 1.0)
	color.a = clamp(velocity.z / 4.0 + 0.5, 0.0, 1.0)
	
	# Set pixel
	image.set_pixel(grid_pos.x, grid_pos.y, color)
	
	# Note: We don't rebuild texture here for performance
	# It will be rebuilt on next simulation update

func spawn_particle_at_world(world_pos: Vector3, material_type: MaterialType, velocity: Vector3 = Vector3.ZERO):
	"""Spawn a single particle at a world position"""
	var grid_pos = world_to_grid(world_pos)
	spawn_particle_at_grid(grid_pos, material_type, velocity)

func spawn_particle_column(base_grid_pos: Vector3i, height: int, material_type: MaterialType):
	"""Spawn a vertical column of particles"""
	for y in range(height):
		var pos = Vector3i(base_grid_pos.x, base_grid_pos.y + y, base_grid_pos.z)
		spawn_particle_at_grid(pos, material_type)

func spawn_particle_box(min_grid: Vector3i, max_grid: Vector3i, material_type: MaterialType):
	"""Spawn particles filling a box region"""
	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			for z in range(min_grid.z, max_grid.z + 1):
				spawn_particle_at_grid(Vector3i(x, y, z), material_type)
	
	# Rebuild texture after batch spawn
	_rebuild_write_texture()
	# Also copy to read buffer so particles are visible immediately
	_sync_write_to_read()

func _sync_write_to_read():
	"""Copy write buffer to read buffer (for initial particle spawn)"""
	for z in range(grid_resolution.z):
		current_read_images[z] = current_write_images[z].duplicate()
	
	if current_read_buffer == particle_texture_a:
		particle_texture_a = Texture2DArray.new()
		particle_texture_a.create_from_images(current_read_images)
		current_read_buffer = particle_texture_a
	else:
		particle_texture_b = Texture2DArray.new()
		particle_texture_b.create_from_images(current_read_images)
		current_read_buffer = particle_texture_b

## Debug Visualization
# TODO: Add debug drawing for grid bounds and particle visualization later

var is_updating: bool = false

func _process(delta):
	if simulate and not is_updating:
		_update_simulation(delta)

func _update_simulation(delta: float):
	"""Main simulation update loop - process each layer"""
	is_updating = true
	
	# Process each Z layer
	for z in range(grid_resolution.z):
		var material = color_rects[z].material as ShaderMaterial
		
		# Set shader parameters for this layer
		material.set_shader_parameter("particle_texture", current_read_buffer)
		material.set_shader_parameter("current_layer", z)
		material.set_shader_parameter("gravity", gravity)
		material.set_shader_parameter("delta_time", delta)
		material.set_shader_parameter("grid_resolution", Vector3(grid_resolution))
		
		# Render this layer
		sub_viewports[z].render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Wait for all viewports to render
	await get_tree().process_frame
	
	# Copy results back to write buffer
	_copy_viewport_results_to_texture()
	
	# Swap buffers for next frame
	swap_buffers()
	
	is_updating = false

func _copy_viewport_results_to_texture():
	"""Copy rendered viewport results back to the write texture"""
	for z in range(grid_resolution.z):
		# Get the rendered image from the viewport
		var viewport_image = viewport_textures[z].get_image()
		
		# Copy to our write images array
		current_write_images[z] = viewport_image
	
	# Rebuild the write texture from updated images
	_rebuild_write_texture()

func _rebuild_write_texture():
	"""Rebuild the write texture from current image data"""
	# Determine which texture is the write buffer and rebuild it
	if current_write_buffer == particle_texture_a:
		particle_texture_a = Texture2DArray.new()
		particle_texture_a.create_from_images(current_write_images)
		current_write_buffer = particle_texture_a
	else:
		particle_texture_b = Texture2DArray.new()
		particle_texture_b.create_from_images(current_write_images)
		current_write_buffer = particle_texture_b
