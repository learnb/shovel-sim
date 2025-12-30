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

## Material lookup
var material_properties: Dictionary = {}

func _ready():
	_initialize_material_properties()
	_initialize_texture_buffers()
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
	
	# Create empty image data for all layers
	var image_data: Array[Image] = []
	for z in range(layers):
		var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))  # Empty particles
		image_data.append(img)
	
	# Create Texture2DArray A
	particle_texture_a = Texture2DArray.new()
	particle_texture_a.create_from_images(image_data)
	
	# Create Texture2DArray B
	particle_texture_b = Texture2DArray.new()
	particle_texture_b.create_from_images(image_data)
	
	# Set initial read/write buffers
	current_read_buffer = particle_texture_a
	current_write_buffer = particle_texture_b

func swap_buffers():
	"""Swap read and write buffers for next frame"""
	var temp = current_read_buffer
	current_read_buffer = current_write_buffer
	current_write_buffer = temp

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

## Debug Visualization

# TODO: Add debug drawing for grid bounds and particle visualization later
