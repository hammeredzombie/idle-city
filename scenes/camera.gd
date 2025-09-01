extends Node3D

@export var pan_speed: float = 0.2
@export var scroll_speed: float = 1.0
@export var edge_margin: int = 20

@export var rotate_sensitivity: float = 0.05   # degrees per pixel (yaw)
@export var tilt_sensitivity: float = 0.05     # degrees per pixel (pitch)

# position and angle constants
const _starting_height: float = 10.0
const _max_camera_pan: float = 50.0

# zoom and swivel constants
const _min_camera_height: float = 3.0
const _max_camera_height: float = 100.0
const _min_pitch_deg: float = -89.0 # 89 to prevent gimbal lock
const _max_pitch_deg: float = -45.0

# variables
var camera_x: float
var camera_z: float
var camera_height: float
var camera_rotation: float
var camera_angle: float
var _is_swiveling: bool = false
var _is_panning: bool = false
var _swivel_mouse_pos: Vector2 = Vector2.ZERO
func _ready() -> void:
	camera_height = _starting_height
	camera_rotation = 0.0
	camera_angle = _min_pitch_deg

func _process(_delta):
	_is_panning = false
	_pan_with_keyboard()
	if _is_swiveling:
		_swivel_camera()
	_apply_transforms()

func _input(_event: InputEvent) -> void:
	## Zoom inputs
	if Input.is_action_just_pressed("zoom_in"):
		_zoom_camera(1)
		# camera_height = max(camera_height - zoom_speed, _min_camera_height)
	elif Input.is_action_just_pressed("zoom_out"):
		_zoom_camera(-1)
		# camera_height = min(camera_height + zoom_speed, _max_camera_height)
	if Input.is_action_just_pressed("swivel"):
		_swivel_mouse_pos = get_viewport().get_mouse_position()
		_is_swiveling = true
	elif Input.is_action_just_released("swivel"):
		_swivel_mouse_pos = Vector2.ZERO
		_is_swiveling = false

func _apply_transforms() -> void:
	position.y = camera_height
	position.x = camera_x
	position.z = camera_z
	rotation.x = deg_to_rad(camera_angle)
	rotation.y = deg_to_rad(camera_rotation)	

func _pan_with_keyboard() -> void:
	var amt_right := Input.get_axis("camera_left", "camera_right")
	var amt_forward := -Input.get_axis("camera_forward", "camera_back") # forward = +1

	if amt_right == 0.0 and amt_forward == 0.0:
		return
	_is_panning = true
	var yaw := deg_to_rad(camera_rotation)
	var new_basis := Basis(Vector3.UP, yaw)
	var right := new_basis.x                  # +X at yaw=0
	var forward := -new_basis.z               # -Z at yaw=0

	var move := (right * amt_right + forward * amt_forward) * pan_speed
	camera_x += move.x
	camera_z += move.z
	camera_x = clamp(camera_x, -_max_camera_pan, _max_camera_pan)
	camera_z = clamp(camera_z, -_max_camera_pan, _max_camera_pan)

func _pan_with_mouse() -> void:
	if _is_swiveling:
		return

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	var amt_right := 0.0
	var amt_forward := 0.0

	if mouse_pos.x <= edge_margin:
		amt_right -= 1.0
	elif mouse_pos.x >= vp_size.x - edge_margin:
		amt_right += 1.0

	if mouse_pos.y <= edge_margin:        # up = forward
		amt_forward += 1.0
	elif mouse_pos.y >= vp_size.y - edge_margin:  # down = backward
		amt_forward -= 1.0

	if amt_right == 0.0 and amt_forward == 0.0:
		return
	var yaw := deg_to_rad(camera_rotation)
	var new_basis := Basis(Vector3.UP, yaw)
	var right := new_basis.x
	var forward := -new_basis.z

	var move := (right * amt_right + forward * amt_forward) * pan_speed
	camera_x += move.x
	camera_z += move.z
	camera_x = clamp(camera_x, -_max_camera_pan, _max_camera_pan)
	camera_z = clamp(camera_z, -_max_camera_pan, _max_camera_pan)

func _swivel_camera() -> void:
	if not _is_swiveling or _swivel_mouse_pos == Vector2.ZERO:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var delta: Vector2 = mouse_pos - _swivel_mouse_pos
	# Yaw: left/right drag
	camera_rotation -= delta.x * rotate_sensitivity * 0.1
	# Pitch: up/down drag (invert if you prefer)
	camera_angle -= delta.y * tilt_sensitivity * 0.1
	camera_angle = clamp(camera_angle, _min_pitch_deg, _max_pitch_deg)

func _zoom_camera(step: int) -> void:
	var forward := -transform.basis.z.normalized()  # local forward
	var cur := Vector3(camera_x, camera_height, camera_z)
	var zoom_speed: float
	if camera_height >= _max_camera_height / 2:
		zoom_speed = 3.0
	elif camera_height <= _max_camera_height / 4:
		zoom_speed = 0.5
	else:
		zoom_speed = 1.0
	var delta := forward * step * zoom_speed * scroll_speed
	var target := cur + delta
	# Respect min/max camera height by scaling if we'd overshoot
	if delta.y != 0.0:
		if target.y < _min_camera_height and delta.y < 0.0:
			var t := (_min_camera_height - cur.y) / delta.y
			delta *= t
		elif target.y > _max_camera_height and delta.y > 0.0:
			var t := (_max_camera_height - cur.y) / delta.y
			delta *= t
	cur += delta
	camera_x = clamp(cur.x, -_max_camera_pan, _max_camera_pan)
	camera_z = clamp(cur.z, -_max_camera_pan, _max_camera_pan)
	camera_height = clamp(cur.y, _min_camera_height, _max_camera_height)
