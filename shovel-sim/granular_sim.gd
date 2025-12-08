extends Node3D

enum CellType { EMPTY, SAND, DIRT, ROCK }
const REPOSE = 0.5		# stable slope (meters of height difference)
const FLOW_RATE = 0.5	# fraction of excess height to move

const grid_width = 128
const grid_height = 128
var grid_size = grid_height * grid_width

var cell_type : PackedInt32Array
var cell_height : PackedFloat32Array

func _ready():
	cell_type.resize(grid_size)
	cell_height.resize(grid_size)
	
	for i in grid_size:
		cell_type[i] = CellType.EMPTY
		cell_height[i] = randf_range(0.0, 10.0)

func get_grid():
	return 

func update_grid():
	for y in range(grid_height):
		for x in range(grid_width):
			process_cell(x, y)

func idx(x, y):
	return x + y * grid_width

func in_bounds(x, y):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func process_cell(x, y):
	var i = idx(x, y)
	var t = cell_type[i]
	var h = cell_height[i]
	
	if h<=0.0:	# empty cell
		return
	
	if t != CellType.SAND:
		return
	
	# Check neighbors
	for off in get_neighbors():
		var nx = x + off.x
		var ny = y + off.y
		
		if not in_bounds(nx, ny):
			continue
		
		var ni = idx(nx, ny)
		var nh = cell_height[ni]
		
		var diff = h - nh
		
		if diff > REPOSE:
			pass

func get_type(x, y):
	return cell_type[idx(x,y)]

func set_type(x, y, t):
	cell_type[idx(x,y)] = t

func get_neighbors():
	return [
		Vector2i(-1, 0),	# left
		Vector2i(1, 0),	# right
		Vector2i(0, -1),	# down
		Vector2i(0, 1),	# up
		
		Vector2i(-1, -1),	# down-left
		Vector2i(1, -1),	# down-right
		Vector2i(-1, 1),	# up-left
		Vector2i(1, 1),	# up-right
	]

	
	
