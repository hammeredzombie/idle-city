extends Node3D

@export var pan_speed: float = 0.20
@export var zoom_speed: float = 0.25
@export var edge_margin: int = 20

var camera_x: float
var camera_z: float

var camera_height: float
var camera_rotation: float
var camera_angle: float

const _starting_height: float = 10.0
const starting_rotation: float = 0.0
const starting_angle: float = -90.0

const _max_height: float = 15.0
const _min_height: float = 1.0

var _boundry_min_x: float
var _boundry_max_x: float
var _boundry_min_z: float
var _boundry_max_z: float

func _ready() -> void:
	camera_height = _starting_height
	camera_angle = starting_angle

func _process(_delta):
	_pan_with_keyboard()
	_pan_with_mouse()
	_clamp_camera()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		camera_height = max(camera_height - zoom_speed, _min_height)
	elif Input.is_action_just_pressed("zoom_out"):
		camera_height = min(camera_height + zoom_speed, _max_height)

func _pan_with_keyboard() -> void:
	position.y = camera_height
	position.x = camera_x
	position.z = camera_z
	rotation.x = deg_to_rad(camera_angle)
	rotation.y = deg_to_rad(camera_rotation)
	var pan_x := 0.0
	var pan_z := 0.0
	pan_x = Input.get_axis("camera_left", "camera_right")
	pan_z = Input.get_axis("camera_forward", "camera_back")
	camera_x += pan_x * pan_speed
	camera_z += pan_z * pan_speed

func _pan_with_mouse() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	if mouse_pos.x <= edge_margin: # move left
		camera_x -= pan_speed
	elif mouse_pos.x >= viewport_size.x - edge_margin: # move right
		camera_x += pan_speed
	if mouse_pos.y <= edge_margin: # move up
		camera_z -= pan_speed
	elif mouse_pos.y >= viewport_size.y - edge_margin: # move down
		camera_z += pan_speed

func _clamp_camera():
	# viewport info
	var vp_size: Vector2i = get_viewport().get_visible_rect().size
	var aspect := float(vp_size.x) / float(vp_size.y)

	# camera angles
	var yaw := deg_to_rad(camera_rotation)              # around Y
	var pitch := deg_to_rad(camera_angle)               # negative when looking down
	var tilt_from_down: float = abs(pitch + PI * 0.5)         # 0 = straight down, up to ~0.785 (45°)

	# FOVs
	var vfov := deg_to_rad($Camera3D.fov)
	var hfov := 2.0 * atan(tan(vfov * 0.5) * aspect)

	# base half-extents at straight-down
	var half_x_cam := camera_height * tan(hfov * 0.5)
	var half_z_cam := camera_height * tan(vfov * 0.5)

	# inflate for tilt (conservative): sec(tilt) = 1 / cos(tilt)
	var inflate: float = 1.0 / max(0.0001, cos(tilt_from_down))
	half_x_cam *= inflate
	half_z_cam *= inflate

	# rotate extents into world axes (AABB of rotated rect)
	var c: float = abs(cos(yaw))
	var s: float = abs(sin(yaw))
	var half_world_x: float = c * half_x_cam + s * half_z_cam
	var half_world_z: float = s * half_x_cam + c * half_z_cam

	# clamp against ground AABB (use your cached padded bounds)
	var min_x: float = _boundry_min_x + half_world_x
	var max_x: float = _boundry_max_x - half_world_x
	var min_z: float = _boundry_min_z + half_world_z
	var max_z: float = _boundry_max_z - half_world_z

	if min_x > max_x or min_z > max_z:
		# footprint larger than boundry -> center
		camera_x = (_boundry_min_x + _boundry_max_x) * 0.5
		camera_z = (_boundry_min_z + _boundry_max_z) * 0.5
	else:
		camera_x = clamp(camera_x, min_x, max_x)
		camera_z = clamp(camera_z, min_z, max_z)
