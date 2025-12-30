extends Node3D

@export var clump_scene: PackedScene
@export var clump_count: int = 1000
@export var pile_radius: float = 1.0

func _ready():
	create_pile()
	
func create_pile():
	for i in range(clump_count):
		var angle = randf() * PI * 2
		var radius = randf() * pile_radius
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf() * 0.2
		var position = Vector3(x, y, z)
		
		var clump_particle = clump_scene.instantiate() as RigidBody3D
		clump_particle.global_position = position
		
		add_child(clump_particle)
		
