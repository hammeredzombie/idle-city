extends GridMap

enum MESH_INDEX {
	straight,
	straight_preview,
	straight_crossing,
	straight_crossing_preview,
	end,
	end_preview,
	end_round,
	end_round_preview,
	bend,
	bend_preview,
	bend_round,
	bend_round_preview,
	intersection,
	intersection_preview,
	intersection_crossing,
	intersection_crossing_preview,
	t_intersection,
	t_intersection_preview,
	t_intersection_crossing,
	t_intersection_crossing_preview,
	driveway_double,
	driveway_double_preview,
	driveway_single,
	driveway_single_preview,
	tile,
	tile_preview,
}

@export var target_layer_y: int = 0
@onready var camera: Camera3D = get_viewport().get_camera_3d()

var _is_building:bool = true
var _is_placing:bool = false
var _is_removing:bool = false
var _preview_active: bool = false
var _preview_cell: Vector3i

var _curr_cell:Vector3i = Vector3i(-1, -1, -1)
var _curr_tile:MESH_INDEX = MESH_INDEX.straight
var _curr_orientation: Basis = Basis()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("road_builder"):
		_is_building = !_is_building

	if not _is_building:
		return

	if event.is_action_pressed("mouse_left"):
		_is_placing = true
		_curr_cell = _get_cell_under_mouse()
		_place_tile(_curr_cell)
	if event.is_action_released("mouse_left"):
		_is_placing = false

	if event.is_action_pressed("mouse_right"):
		_is_removing = true
		_curr_cell = _get_cell_under_mouse()
		_remove_tile(_curr_cell)
	if event.is_action_released("mouse_right"):
		_is_removing = false

	if event.is_action_pressed("rotate_right"):
		_curr_orientation = _curr_orientation.rotated(Vector3.UP, deg_to_rad(90))
		_curr_cell = _get_cell_under_mouse()
		_preview_tile(_curr_cell)
	if event.is_action_pressed("rotate_left"):
		_curr_orientation = _curr_orientation.rotated(Vector3.UP, deg_to_rad(-90))
		_curr_cell = _get_cell_under_mouse()
		_preview_tile(_curr_cell)

func _process(_delta: float) -> void:
	# Hover preview
	if _is_building and not (_is_placing or _is_removing):
		var next_cell: Vector3i = _get_cell_under_mouse()

		# if we moved to a different cell, remove the old preview
		if _preview_active and next_cell != _preview_cell:
			# implement this to undo whatever _preview_tile() did
			_remove_preview(_preview_cell)
			_preview_active = false

		# show preview on the current hover cell (first time or moved)
		if not _preview_active or next_cell != _preview_cell:
			_preview_tile(next_cell)
			_preview_cell = next_cell
			_preview_active = true

	# Drag and place / remove
	if _is_building and (_is_placing or _is_removing):
		var next_cell: Vector3i = _get_cell_under_mouse()

		# clear any hover preview while dragging
		if _preview_active:
			_remove_preview(_preview_cell)
			_preview_active = false

		# act only when the cell changes
		if next_cell != _curr_cell:
			_curr_cell = next_cell
			if _is_placing:
				_place_tile(_curr_cell)
			if _is_removing:
				_remove_tile(_curr_cell)

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
	set_cell_item(cell, _curr_tile, get_orthogonal_index_from_basis(_curr_orientation))

func _remove_tile(cell: Vector3i) -> void:
	set_cell_item(cell, -1, 0)

func _preview_tile(cell: Vector3i) -> void:
	var item_index = get_cell_item(cell)
	if item_index >= 0 and item_index <= MAX_MESH_INDEX:
		return
	set_cell_item(cell, _get_preview_tile(_curr_tile), get_orthogonal_index_from_basis(_curr_orientation))

func _remove_preview(cell: Vector3i) -> void:
	if get_cell_item(cell) >= MAX_MESH_INDEX + 1:
		set_cell_item(cell, -1, 0)

func _get_preview_tile(index: int) -> int:
	var preview_index = index + MAX_MESH_INDEX + 1
	return preview_index

