extends Camera3D

# Speed variables for camera movement and rotation
@export var move_speed: float = 5.0
@export var look_speed: float = 2.0

# Variables to store the current rotation
var yaw: float = 0.0
var pitch: float = 0.0

func _process(delta: float) -> void:
	var direction = Vector3.ZERO

	# Handle movement inputs
	if Input.is_action_pressed("camera_forward"):
		direction += -transform.basis.z
	if Input.is_action_pressed("camera_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("camera_left"):
		direction += -transform.basis.x
	if Input.is_action_pressed("camera_right"):
		direction += transform.basis.x
	if Input.is_action_pressed("camera_up"):
		direction += transform.basis.y
	if Input.is_action_pressed("camera_down"):
		direction -= transform.basis.y

	# Normalize direction vector
	direction = direction.normalized()

	# Move the camera
	if direction.length() > 0:
		position += direction * move_speed * delta

	# Handle rotation inputs
	if Input.is_action_pressed("camera_turn_left"):
		yaw += look_speed * delta
	if Input.is_action_pressed("camera_turn_right"):
		yaw -= look_speed * delta

	if Input.is_action_pressed("camera_look_up"):
		pitch -= look_speed * delta
	if Input.is_action_pressed("camera_look_down"):
		pitch += look_speed * delta

	# Clamp pitch to avoid gimbal lock
	pitch = clamp(pitch, -89.0, 89.0)

	# Apply rotation
	rotation_degrees = Vector3(pitch, yaw, 0)
