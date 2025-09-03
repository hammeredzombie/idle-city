extends GridMap

enum MESH_INDEX {
	SPLIT,
	STRAIGHT,
	TILE,
	BEND_ROUND,
	BEND_SQUARE,
	STRAIGHT_CROSSING,
	FOUR_WAY,
	FOUR_WAY_CROSSING,
	BEND_2X2,
	BEND_INTERSECTION_2X2,
	STRAIGHT_DRIVEWAY_DOUBLE,
	STRAIGHT_DRIVEWAY_SINGLE,
	STRAIGHT_END_SQUARE,
	STRAIGHT_END_ROUND,
	T_INTERSECTION,
	T_INTERSECTION_CROSSING,
	ROUND_ABOUT_3X3,
	INVALID
}

@export var target_layer_y: int = 0
@onready var camera: Camera3D = get_viewport().get_camera_3d()

var _is_building:bool = true
var _is_placing:bool = false
var _is_removing:bool = false

var _curr_cell:Vector3i = Vector3i(-1, -1, -1)
var _curr_tile:MESH_INDEX = MESH_INDEX.STRAIGHT
var _curr_orientation:int

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("road_builder"):
		_is_building = !_is_building

	if _is_building:
		if event.is_action_pressed("mouse_left"):
			_is_placing = true
			_place_tile(_curr_cell)
		if event.is_action_released("mouse_left"):
			_is_placing = false

		if event.is_action_pressed("mouse_right"):
			_is_removing = true
			_remove_tile(_curr_cell)
		if event.is_action_released("mouse_right"):
			_is_removing = false

func _process(_delta: float) -> void:
	if _is_building and not (_is_placing or _is_removing):
		_curr_cell = _get_cell_under_mouse()
	## Drag and place
	if _is_building and (_is_placing or _is_removing):
		var last_cell = _curr_cell
		var next_cell:Vector3i = _get_cell_under_mouse()
		print('last_cell: ', last_cell, ' next_cell: ', next_cell)
		if next_cell != last_cell:
			last_cell = next_cell
			if _is_placing:
				_place_tile(last_cell)
			if _is_removing:
				_remove_tile(last_cell)

func _get_cell_under_mouse() -> Vector3i:
	if camera == null:
		return Vector3i(-1, -1, -1)

	# 1) Mouse ray in world space
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var from_w: Vector3 = camera.project_ray_origin(mouse)
	var dir_w: Vector3 = camera.project_ray_normal(mouse)

	# 2) Transform ray into GridMap local space (no xform)
	var inv: Transform3D = global_transform.affine_inverse()
	var from_l: Vector3 = inv * from_w              # point -> use full transform
	var dir_l: Vector3 = (inv.basis * dir_w).normalized()  # direction -> basis only

	# 3) Intersect with horizontal plane at the target layer
	var plane_y: float = float(target_layer_y) * cell_size.y
	if absf(dir_l.y) < 0.00001:
		return Vector3i(-1, -1, -1)

	var t: float = (plane_y - from_l.y) / dir_l.y
	if t < 0.0:
		return Vector3i(-1, -1, -1)

	var hit_l: Vector3 = from_l + dir_l * t

	# 4) Convert local point -> cell index
	var cell: Vector3i = local_to_map(hit_l)
	cell.y = target_layer_y
	return cell

func _place_tile(cell: Vector3i) -> void:
	set_cell_item(cell, _curr_tile, _curr_orientation)

func _remove_tile(cell: Vector3i) -> void:
	set_cell_item(cell, -1, 0)
