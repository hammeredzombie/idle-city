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

enum THUMBNAIL_INDEX {
	straight,
	straight_crossing,
	end,
	end_round,
	bend,
	bend_round,
	intersection,
	intersection_crossing,
	t_intersection,
	t_intersection_crossing,
	driveway_double,
	driveway_single,
	tile,
}

const thumbnails = [
	preload("res://assets/tiles/thumbnails/straight.png"),
	preload("res://assets/tiles/thumbnails/straight-crossing.png"),
	preload("res://assets/tiles/thumbnails/end.png"),
	preload("res://assets/tiles/thumbnails/end-round.png"),
	preload("res://assets/tiles/thumbnails/bend.png"),
	preload("res://assets/tiles/thumbnails/bend-round.png"),
	preload("res://assets/tiles/thumbnails/intersection.png"),
	preload("res://assets/tiles/thumbnails/intersection-crossing.png"),
	preload("res://assets/tiles/thumbnails/t-intersection.png"),
	preload("res://assets/tiles/thumbnails/t-intersection-crossing.png"),
	preload("res://assets/tiles/thumbnails/driveway-double.png"),
	preload("res://assets/tiles/thumbnails/driveway-single.png"),
	preload("res://assets/tiles/thumbnails/tile.png"),
]

enum TILE_TYPE {
	straight,
	bend,
	intersection
}

const MIN_MESH_INDEX = MESH_INDEX.straight
const MAX_MESH_INDEX = MESH_INDEX.tile
const MIN_MESH_INDEX_STRAIGHT = MESH_INDEX.straight
const MAX_MESH_INDEX_STRAIGHT = MESH_INDEX.end_round
const MIN_MESH_INDEX_BEND = MESH_INDEX.bend
const MAX_MESH_INDEX_BEND = MESH_INDEX.bend_round
const MIN_MESH_INDEX_INTERSECTION = MESH_INDEX.intersection
const MAX_MESH_INDEX_INTERSECTION = MESH_INDEX.t_intersection_crossing

var _is_building:bool = true
var _is_placing:bool = false
var _is_removing:bool = false
var _preview_active: bool = false
var _preview_cell: Vector3i
var _target_layer_y: int = 0

var _curr_cell:Vector3i = Vector3i(-1, -1, -1)
var _curr_tile:int = MESH_INDEX.straight
# var _curr_tile_straight:int = MESH_INDEX.straight
# var _curr_tile_bend:int = MESH_INDEX.bend
# var _curr_tile_intersection:int = MESH_INDEX.intersection
# var _curr_type:int = TILE_TYPE.straight
var _curr_orientation: Basis = Basis()

@onready var grid: GridMap = self
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var ui: Control = get_node('UI')

func _ready() -> void:
	if grid.mesh_library == null:
		push_error("GridMap has no MeshLibrary assigned.")
		set_process(false)
		set_process_input(false)
		return
	_assign_mesh_indices()
	ui.visible = _is_building

func _input(event: InputEvent) -> void:
	#enable building
	if event.is_action_pressed("road_builder"):
		_is_building = !_is_building
		ui.visible = _is_building

	if not _is_building:
		return

	#place tile
	if event.is_action_pressed("mouse_left"):
		_is_placing = true
		_curr_cell = _get_cell_under_mouse()
		_place_tile(_curr_cell)
	if event.is_action_released("mouse_left"):
		_is_placing = false

	#remove tile
	if event.is_action_pressed("mouse_right"):
		_is_removing = true
		_curr_cell = _get_cell_under_mouse()
		_remove_tile(_curr_cell)
	if event.is_action_released("mouse_right"):
		_is_removing = false

	#rotate tile
	if event.is_action_pressed("rotate_right"):
		_curr_orientation = _curr_orientation.rotated(Vector3.UP, deg_to_rad(90))
		_curr_cell = _get_cell_under_mouse()
		_preview_tile(_curr_cell)
	if event.is_action_pressed("rotate_left"):
		_curr_orientation = _curr_orientation.rotated(Vector3.UP, deg_to_rad(-90))
		_curr_cell = _get_cell_under_mouse()
		_preview_tile(_curr_cell)
	
	#change tile type
	if event.is_action_pressed("build_straight"):
		# _choose_or_cycle_type(TILE_TYPE.straight)
		pass
	elif event.is_action_pressed("build_bend"):
		# _choose_or_cycle_type(TILE_TYPE.bend)
		pass
	elif event.is_action_pressed("build_intersection"):
		# _choose_or_cycle_type(TILE_TYPE.intersection)
		pass

func _process(_delta: float) -> void:
	if not _is_building:
		if _preview_active:
			_remove_preview(_preview_cell)
			_preview_active = false
		return
	# Preview tile
	if _is_building and not (_is_placing or _is_removing):
		var next_cell: Vector3i = _get_cell_under_mouse()

		# if we moved to a different cell, remove the old preview
		if _preview_active and next_cell != _preview_cell:
			_remove_preview(_preview_cell)
			_preview_active = false

		# show preview on the current hover cell (first time or moved)
		if not _preview_active or next_cell != _preview_cell:
			_preview_tile(next_cell)
			_preview_cell = next_cell
			_preview_active = true

	# Drag to place / remove
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
	var plane_y: float = float(_target_layer_y) * cell_size.y
	if absf(dir_l.y) < 0.00001:
		return Vector3i(-1, -1, -1)

	var t: float = (plane_y - from_l.y) / dir_l.y
	if t < 0.0:
		return Vector3i(-1, -1, -1)

	var hit_l: Vector3 = from_l + dir_l * t

	# 4) Convert local point -> cell index
	var cell: Vector3i = local_to_map(hit_l)
	cell.y = _target_layer_y
	return cell

func _place_tile(cell: Vector3i) -> void:
	set_cell_item(cell, _curr_tile, get_orthogonal_index_from_basis(_curr_orientation))

func _remove_tile(cell: Vector3i) -> void:
	set_cell_item(cell, -1, 0)

func _preview_tile(cell: Vector3i) -> void:
	var item_index = get_cell_item(cell)
	if item_index == -1:
		set_cell_item(cell, _get_tile_preview(_curr_tile), get_orthogonal_index_from_basis(_curr_orientation))

func _remove_preview(cell: Vector3i) -> void:
	# only remove if a preview tile
	if get_cell_item(cell) % 2 == 1: # preview tiles are odd indexed
		set_cell_item(cell, -1, 0)

func _get_tile_preview(index: int) -> int:
	var preview_index = index + 1
	return preview_index

#UI thumbnails
# func _choose_or_cycle_type(type:TILE_TYPE):
# 	if type == _curr_type:
# 		match type:
# 			TILE_TYPE.straight:
# 				pass
# 			TILE_TYPE.bend:
# 				pass
# 			TILE_TYPE.intersection:
# 				pass
# 	else:
# 		_curr_type = type
# 		match type:
# 			TILE_TYPE.straight:
# 				_curr_tile = _curr_tile_straight
# 			TILE_TYPE.bend:
# 				_curr_tile = _curr_tile_bend
# 			TILE_TYPE.intersection:
# 				_curr_tile = _curr_tile_intersection

# func _change_thumbnail(_index: MESH_THUMBNAIL_INDEX):
# 	pass

# func _get_tile_thumbnail(index: MESH_THUMBNAIL_INDEX) -> int:
# 	return index

# func _cycle_tile(type:TILE_TYPE):
# 	match type:
# 		TILE_TYPE.straight:
# 			_curr_tile_straight += 2
# 			if _curr_tile_straight > MAX_MESH_INDEX_STRAIGHT:
# 				_curr_tile_straight = MESH_INDEX.straight
# 			_curr_tile = _curr_tile_straight
# 			straight_thumbnail.texture = thumbnails[_get_tile_thumbnail(MESH_THUMBNAIL_INDEX.straight)]
# 		TILE_TYPE.bend:
# 			_curr_tile_bend += 2
# 			if _curr_tile_bend > MAX_MESH_INDEX_BEND:
# 				_curr_tile_bend = MESH_INDEX.bend
# 			_curr_tile = _curr_tile_bend
# 		TILE_TYPE.intersection:
# 			_curr_tile_intersection += 2
# 			if _curr_tile_intersection > MAX_MESH_INDEX_INTERSECTION:
# 				_curr_tile_intersection = MESH_INDEX.intersection
# 			_curr_tile = _curr_tile_intersection

func _assign_mesh_indices() -> void:
	var lib: MeshLibrary = grid.mesh_library
	print(lib)
