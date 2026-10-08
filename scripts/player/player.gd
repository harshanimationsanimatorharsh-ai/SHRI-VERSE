extends CharacterBody3D
class_name ShriPlayer


@export_category("Movement")
@export var walk_speed: float = 3.2
@export var sprint_speed: float = 5.8
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var jump_velocity: float = 5.2
@export var rotation_speed: float = 10.0


@export_category("Camera")
@export var camera_sensitivity: float = 0.003
@export var camera_min_pitch: float = deg_to_rad(-55.0)
@export var camera_max_pitch: float = deg_to_rad(35.0)


@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_pitch: Node3D = $CameraPivot/CameraPitch


var gravity: float = ProjectSettings.get_setting(
	"physics/3d/default_gravity"
)

var camera_yaw: float = 0.0
var camera_pitch_angle: float = deg_to_rad(-12.0)


func _ready() -> void:
	camera_yaw = rotation.y
	camera_pivot.rotation.y = camera_yaw
	camera_pitch_angle = deg_to_rad(-12.0)
	camera_pitch.rotation.x = camera_pitch_angle

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera_yaw -= event.relative.x * camera_sensitivity
			camera_pitch_angle -= event.relative.y * camera_sensitivity

			camera_pitch_angle = clamp(
				camera_pitch_angle,
				camera_min_pitch,
				camera_max_pitch
			)

			camera_pivot.rotation.y = camera_yaw
			camera_pitch.rotation.x = camera_pitch_angle


	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta


	# Jump
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity


	# Keyboard movement
	var input_x: float = 0.0
	var input_y: float = 0.0

	if Input.is_key_pressed(KEY_A):
		input_x -= 1.0

	if Input.is_key_pressed(KEY_D):
		input_x += 1.0

	if Input.is_key_pressed(KEY_W):
		input_y += 1.0

	if Input.is_key_pressed(KEY_S):
		input_y -= 1.0


	var input_vector := Vector2(input_x, input_y)

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()


	# Camera-relative movement
	var camera_basis: Basis = camera_pivot.global_transform.basis

	var forward: Vector3 = -camera_basis.z
	var right: Vector3 = camera_basis.x

	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()


	var move_direction: Vector3 = (
		right * input_vector.x
		+ forward * input_vector.y
	)

	if move_direction.length_squared() > 1.0:
		move_direction = move_direction.normalized()


	# Speed
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT)

	var target_speed: float = (
		sprint_speed
		if is_sprinting
		else walk_speed
	)

	var target_velocity: Vector3 = (
		move_direction * target_speed
	)


	# Smooth movement
	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_rate: float = (
		acceleration
		if move_direction.length_squared() > 0.01
		else deceleration
	)

	horizontal_velocity = horizontal_velocity.move_toward(
		target_velocity,
		movement_rate * delta
	)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


	# Rotate player toward movement direction
	if move_direction.length_squared() > 0.01:

		var target_angle := atan2(
			move_direction.x,
			move_direction.z
		)

		rotation.y = lerp_angle(
			rotation.y,
			target_angle,
			rotation_speed * delta
		)


	move_and_slide()
