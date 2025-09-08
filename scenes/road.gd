extends GridMap

# Grid map setup
const MESH_NAME: Dictionary = {
	"straight": 'straight',
	"straight_preview": 'straight_preview',
	"straight_crossing": 'straight-crossing',
	"straight_crossing_preview": 'straight-crossing_preview',
	"end": 'end',
	"end_preview": 'end_preview',
	"end_round": 'end-round',
	"end_round_preview": 'end-round_preview',
	"bend": 'bend',
	"bend_preview": 'bend_preview',
	"bend_round": 'bend-round',
	"bend_round_preview": 'bend-round_preview',
	"intersection": 'intersection',
	"intersection_preview": 'intersection_preview',
	"intersection_crossing": 'intersection-crossing',
	"intersection_crossing_preview": 'intersection-crossing_preview',
	"t_intersection": 't-intersection',
	"t_intersection_preview": 't-intersection_preview',
	"t_intersection_crossing": 't-intersection-crossing',
	"t_intersection_crossing_preview": 't-intersection-crossing_preview',
	"driveway_double": 'driveway-double',
	"driveway_double_preview": 'driveway-double_preview',
	"driveway_single": 'driveway-single',
	"driveway_single_preview": 'driveway-single_preview',
	"tile": 'tile',
	"tile_preview": 'tile_preview',
	"tile_delete": 'tile-delete',
	"tile_delete_preview": 'tile-delete_preview'
}

const MESH_ORDER: Array[String] = [
	'straight',
	'straight_preview',
	'straight_crossing',
	'straight_crossing_preview',
	'end',
	'end_preview',
	'end_round',
	'end_round_preview',
	'bend',
	'bend_preview',
	'bend_round',
	'bend_round_preview',
	'intersection',
	'intersection_preview',
	'intersection_crossing',
	'intersection_crossing_preview',
	't_intersection',
	't_intersection_preview',
	't_intersection_crossing',
	't_intersection_crossing_preview',
	'driveway_double',
	'driveway_double_preview',
	'driveway_single',
	'driveway_single_preview',
	'tile',
	'tile_preview',
	'tile_delete',
	'tile_delete_preview'
]

# mesh indexing
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
	tile_delete,
	tile_delete_preview
}

const MIN_MESH_INDEX = MESH_INDEX.straight
const MIN_MESH_INDEX_STRAIGHT = MESH_INDEX.straight
const MAX_MESH_INDEX_STRAIGHT = MESH_INDEX.end_round
const MIN_MESH_INDEX_BEND = MESH_INDEX.bend
const MAX_MESH_INDEX_BEND = MESH_INDEX.bend_round
const MIN_MESH_INDEX_INTERSECTION = MESH_INDEX.intersection
const MAX_MESH_INDEX_INTERSECTION = MESH_INDEX.t_intersection_crossing

enum TILE_TYPE {
	straight,
	bend,
	intersection
}

enum MESH_THUMBNAIL_INDEX {
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
	null,
	preload("res://assets/tiles/thumbnails/straight-crossing.png"),
	null,
	preload("res://assets/tiles/thumbnails/end.png"),
	null,
	preload("res://assets/tiles/thumbnails/end-round.png"),
	null,
	preload("res://assets/tiles/thumbnails/bend.png"),
	null,
	preload("res://assets/tiles/thumbnails/bend-round.png"),
	null,
	preload("res://assets/tiles/thumbnails/intersection.png"),
	null,
	preload("res://assets/tiles/thumbnails/intersection-crossing.png"),
	null,
	preload("res://assets/tiles/thumbnails/t-intersection.png"),
	null,
	preload("res://assets/tiles/thumbnails/t-intersection-crossing.png"),
	null,
	preload("res://assets/tiles/thumbnails/driveway-double.png"),
	null,
	preload("res://assets/tiles/thumbnails/driveway-single.png"),
	null,
	preload("res://assets/tiles/thumbnails/tile.png"),
	null,
]

var _is_building:bool = false
var _is_placing:bool = false
var _is_deleting_mode:bool = false
var _is_deleting:bool = false
var _preview_active: bool = false
var _preview_cell: Vector3i
var _tile_to_delete: Array = [-1,-1] # [item index, item orientation]
var _target_layer_y: int = 0

var _curr_cell:Vector3i = Vector3i(-1, -1, -1)
var _curr_tile:int = MESH_INDEX.straight
var _curr_tile_straight:int = MESH_INDEX.straight
var _curr_tile_bend:int = MESH_INDEX.bend
var _curr_tile_intersection:int = MESH_INDEX.intersection
var _curr_type:int = TILE_TYPE.straight
var _curr_orientation: Basis = Basis()

var meshes: Array[int]

@onready var grid: GridMap = self
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var ui: Control = get_node('UI')
@onready var bulldozer: Control = get_node('Bulldozer')
@onready var straight_thumbnail: TextureButton = ui.get_node('straight')
@onready var bend_thumbnail: TextureButton = ui.get_node('bend')
@onready var intersection_thumbnail: TextureButton = ui.get_node('intersection')

func _ready() -> void:
	if grid.mesh_library == null:
		push_error("GridMap has no MeshLibrary assigned.")
		set_process(false)
		set_process_input(false)
		return
	_assign_mesh_indices()
	ui.visible = false
	bulldozer.visible = false
	_switch_type() # highlight starting build type

func _input(event: InputEvent) -> void:
	#enable building
	if event.is_action_pressed("road_build"):
		_is_building = !_is_building
		ui.visible = _is_building
		_is_deleting_mode = false
		bulldozer.visible = false
		if _preview_active:
			_remove_preview(_preview_cell)
		_preview_active = false
		_tile_to_delete = [-1, -1]
		# if not _is_building:
		# 	_remove_preview(_curr_cell)
		# 	_preview_active = false
		# 	return

	if event.is_action_pressed("road_delete"):
		_is_deleting_mode = !_is_deleting_mode
		bulldozer.visible = _is_deleting_mode
		_is_building = false
		ui.visible = false
		_curr_cell = _get_cell_under_mouse()
		if _preview_active:
			_remove_preview(_preview_cell)
		_preview_active = false
		_tile_to_delete = [-1, -1]

	if _is_building:
		#place tile
		if event.is_action_pressed("place_tile"):
			_is_placing = true
			_curr_cell = _get_cell_under_mouse()
			_place_tile(_curr_cell)
		if event.is_action_released("place_tile"):
			_is_placing = false
		#rotate tile
		if event.is_action_pressed("rotate_tile"):
			_curr_orientation = _curr_orientation.rotated(Vector3.UP, deg_to_rad(90))
			_curr_cell = _get_cell_under_mouse()
			_remove_preview(_curr_cell)
			_preview_tile(_curr_cell)
		if event.is_action_pressed("rotate_tile_ccw"):
			_curr_orientation = _curr_orientation.rotated(Vector3.UP, deg_to_rad(-90))
			_curr_cell = _get_cell_under_mouse()
			_remove_preview(_curr_cell)
			_preview_tile(_curr_cell)
		#change tile type
		if event.is_action_pressed("build_straight"):
			_choose_or_cycle_type(TILE_TYPE.straight)
		elif event.is_action_pressed("build_bend"):
			_choose_or_cycle_type(TILE_TYPE.bend)
		elif event.is_action_pressed("build_intersection"):
			_choose_or_cycle_type(TILE_TYPE.intersection)

	if _is_deleting_mode:
		#delete tile
		if event.is_action_pressed("delete_tile"):
			_is_deleting = true
			_curr_cell = _get_cell_under_mouse()
			_delete_tile(_curr_cell)
		if event.is_action_released("delete_tile"):
			_is_deleting = false	

func _process(_delta: float) -> void:
	# If neither mode is active, clear any leftover preview and bail.
	if not _is_building and not _is_deleting_mode:
		if _preview_active:
			_remove_preview(_preview_cell)
			_preview_active = false
		return

	# =========================
	# Build mode (hover + drag)
	# =========================
	if _is_building:
		# Hover preview (only when not dragging)
		if not _is_placing:
			var next_cell: Vector3i = _get_cell_under_mouse()
			if _preview_active and next_cell != _preview_cell:
				_remove_preview(_preview_cell)
				_preview_active = false
			if not _preview_active or next_cell != _preview_cell:
				_preview_tile(next_cell)
				_preview_cell = next_cell
				_preview_active = true
		# Drag place
		if _is_placing:
			var next_cell: Vector3i = _get_cell_under_mouse()
			if _preview_active:
				_remove_preview(_preview_cell)
				_preview_active = false
			if next_cell != _curr_cell:
				_curr_cell = next_cell
				_place_tile(_curr_cell)
		return

	# ==========================
	# Delete mode (hover + drag)
	# ==========================
	if _is_deleting_mode:
		# Hover delete preview (only when not dragging)
		if not _is_deleting:
			var next_cell: Vector3i = _get_cell_under_mouse()
			if _preview_active and next_cell != _preview_cell:
				_remove_preview(_preview_cell)
				_preview_active = false
			if not _preview_active or next_cell != _preview_cell:
				_preview_tile(next_cell) # will place delete preview if something exists there
				_preview_cell = next_cell
				_preview_active = true
		# Drag delete
		if _is_deleting:
			var next_cell: Vector3i = _get_cell_under_mouse()
			if _preview_active:
				_remove_preview(_preview_cell)
				_preview_active = false
			if next_cell != _curr_cell:
				_curr_cell = next_cell
				_delete_tile(_curr_cell)


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
	set_cell_item(cell, meshes[_curr_tile], get_orthogonal_index_from_basis(_curr_orientation))

func _delete_tile(cell: Vector3i) -> void:
	set_cell_item(cell, -1, 0)

func _preview_tile(cell: Vector3i) -> void:
	var tile_item_index = get_cell_item(cell)
	var tile_item_orientation = get_cell_item_orientation(cell)
	_tile_to_delete[0] = tile_item_index
	_tile_to_delete[1] = tile_item_orientation
	if _is_building and tile_item_index == -1: # preview on empty tiles
		set_cell_item(cell, meshes[_get_tile_preview_index(_curr_tile)], get_orthogonal_index_from_basis(_curr_orientation))
	if _is_building and tile_item_index != meshes[_curr_tile]: # preview on different tiles
		set_cell_item(cell, meshes[_get_tile_preview_index(_curr_tile)], get_orthogonal_index_from_basis(_curr_orientation))
	if _is_building and tile_item_index == meshes[_curr_tile] and tile_item_orientation != get_orthogonal_index_from_basis(_curr_orientation): # preview on different orientation
		set_cell_item(cell, meshes[_get_tile_preview_index(_curr_tile)], get_orthogonal_index_from_basis(_curr_orientation))


	if _is_deleting_mode and tile_item_index != -1:
		set_cell_item(cell, meshes[MESH_INDEX.tile_delete_preview])

func _remove_preview(cell: Vector3i) -> void:
	var meshLibraryIndex = get_cell_item(cell)
	if meshLibraryIndex == -1:
		return
	var previewIndex = meshes.find(meshLibraryIndex)
	if previewIndex == -1:
		return
	# Remove odd index preview tiles or delete preview
	if previewIndex % 2 == 1 or previewIndex == MESH_INDEX.tile_delete_preview  : # preview tiles are odd indexed
		set_cell_item(cell, _tile_to_delete[0], _tile_to_delete[1])

func _get_tile_preview_index(index: int) -> int:
	var preview_index = index + 1
	return preview_index

#UI thumbnails
func _choose_or_cycle_type(type:TILE_TYPE):
	if type == _curr_type:
		_cycle_tile()
	else:
		_curr_type = type
		_switch_type()
	_curr_cell = _get_cell_under_mouse()
	_remove_preview(_curr_cell)	
	_preview_tile(_curr_cell)

func _switch_type():
	match _curr_type:
		TILE_TYPE.straight:
			_curr_tile = _curr_tile_straight
			straight_thumbnail.self_modulate = Color(2.0, 2.0, 2.0)
			bend_thumbnail.self_modulate = Color(1.0, 1.0, 1.0)
			intersection_thumbnail.self_modulate = Color(1.0, 1.0, 1.0)
		TILE_TYPE.bend:
			_curr_tile = _curr_tile_bend
			straight_thumbnail.self_modulate = Color(1.0, 1.0, 1.0)
			bend_thumbnail.self_modulate = Color(2.0, 2.0, 2.0)
			intersection_thumbnail.self_modulate = Color(1.0, 1.0, 1.0)
		TILE_TYPE.intersection:
			_curr_tile = _curr_tile_intersection
			straight_thumbnail.self_modulate = Color(1.0, 1.0, 1.0)
			bend_thumbnail.self_modulate = Color(1.0, 1.0, 1.0)
			intersection_thumbnail.self_modulate = Color(2.0, 2.0, 2.0)

func _cycle_tile():
	match _curr_type:
		TILE_TYPE.straight:
			_curr_tile_straight += 2
			if _curr_tile_straight > MAX_MESH_INDEX_STRAIGHT:
				_curr_tile_straight = MESH_INDEX.straight
			_curr_tile = _curr_tile_straight
			straight_thumbnail.texture_normal = thumbnails[_curr_tile]
		TILE_TYPE.bend:
			_curr_tile_bend += 2
			if _curr_tile_bend > MAX_MESH_INDEX_BEND:
				_curr_tile_bend = MESH_INDEX.bend
			_curr_tile = _curr_tile_bend
			bend_thumbnail.texture_normal = thumbnails[_curr_tile]
		TILE_TYPE.intersection:
			_curr_tile_intersection += 2
			if _curr_tile_intersection > MAX_MESH_INDEX_INTERSECTION:
				_curr_tile_intersection = MESH_INDEX.intersection
			_curr_tile = _curr_tile_intersection
			intersection_thumbnail.texture_normal = thumbnails[_curr_tile]

#
func _assign_mesh_indices() -> void:
	var lib: MeshLibrary = grid.mesh_library
	for mesh in MESH_ORDER:
		var meshName = MESH_NAME[mesh]
		var meshIndex = lib.find_item_by_name(meshName)
		if meshIndex == -1:
			push_error("could not find mesh with name: ", meshName)
			set_process(false)
			set_process_input(false)
			return
		meshes.push_back(meshIndex)
