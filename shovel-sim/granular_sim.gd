extends Node3D

enum CellType { EMPTY, SAND, DIRT, ROCK }
const REPOSE = 0.5		# stable slope (meters of height difference)
const FLOW_RATE = 0.5	# fraction of excess height to move

const grid_width = 64
const grid_height = 64
var grid_size = grid_height * grid_width
var update_indices = []

var cell_type : PackedInt32Array
var cell_height : PackedFloat32Array

func _ready():
	cell_type.resize(grid_size)
	cell_height.resize(grid_size)
	
	update_indices.resize(grid_size)
	for i in range(grid_size):
		update_indices[i] = i
	
	for i in grid_size:
		cell_type[i] = CellType.SAND
		cell_height[i] = randf_range(0.0, 50.0)

func _process(_delta):
	update_grid()

func get_grid():
	return 

func update_grid():
	# shuffle cell update order
	update_indices.shuffle()
	for i in update_indices:
		process_cell(i % grid_width, i / grid_width)

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
	
	#cell_height[i] = randf_range(0.0, 10.0)
	
	# try spreading to neighbors
	# TODO: randomize how we iterate the neighbors to "balance" 
	# 		preference for spreading
	for off in get_neighbors():
		var nx = x + off.x
		var ny = y + off.y
		
		if not in_bounds(nx, ny):
			continue
		
		var ni = idx(nx, ny)
		var nh = cell_height[ni]
		
		var diff = h - nh
		
		# only move material if slope exceeds angle of repose
		if diff > REPOSE:
			var excess = diff - REPOSE
			var move_amount = excess * FLOW_RATE
			
			cell_height[i] -= move_amount
			cell_height[ni] += move_amount
			
			h -= move_amount
			
			if h <= 0.0:
				break

func get_type(x, y):
	return cell_type[idx(x,y)]

func set_type(x, y, t):
	cell_type[idx(x,y)] = t

func get_neighbors():
	return [
		Vector2i(-1, 0), # left
		Vector2i(1, 0),  # right
		Vector2i(0, -1), # down
		Vector2i(0, 1),  # up
		
		Vector2i(-1, -1), # down-left
		Vector2i(1, -1),  # down-right
		Vector2i(-1, 1),  # up-left
		Vector2i(1, 1),   # up-right
	]
