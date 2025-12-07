extends Node3D

enum CellType { EMPTY, SAND, DIRT, ROCK }

const grid_width = 128
const grid_height = 128
var grid_size = grid_height * grid_width

var cell_type : PackedInt32Array
var cell_velocity : PackedVector2Array
var cell_settle : PackedFloat32Array

func _ready():
	cell_type.resize(grid_size)
	cell_velocity.resize(grid_size)
	cell_settle.resize(grid_size)
	
	for i in grid_size:
		cell_type[i] = CellType.EMPTY
		cell_velocity[i] = Vector2.ZERO
		cell_settle[i] = 0.0

func update_grid():
	for y in range(grid_height - 2, -1, -1): # bottom to top
		for x in range(grid_width):
			process_cell(x, y)

func idx(x, y):
	return x + y * grid_width

func in_bounds(x, y):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func process_cell(x, y):
	var i = idx(x, y)
	var t = cell_type[i]
	
	if t != CellType.SAND:
		return
	
	# Check below
	
	# Check diagonals

func get_type(x, y):
	return cell_type[idx(x,y)]

func set_type(x, y, t):
	cell_type[idx(x,y)] = t

func swap_cells(x1, y1, x2, y2):
	var i1 = idx(x1, y1)
	var i2 = idx(x2, y2)
	
	var tmp_type = cell_type[i1]
	cell_type[i1] = cell_type[i2]
	cell_type[i2] = tmp_type
	
	var tmp_vel = cell_velocity[i1]
	cell_velocity[i1] = cell_velocity[i2]
	cell_velocity[i2] = tmp_vel
	
	var tmp_st = cell_settle[i1]
	cell_settle[i1] = cell_settle[i2]
	cell_settle[i2] = tmp_st
	
	
