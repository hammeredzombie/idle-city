extends GridMap
class_name IslandBuilder

@export var islands: Array[Dictionary]
@onready var Grid: GridMap = self

enum MESH_INDEX { CENTER, EDGE, CORNER, GRID_OVERLAY }
enum CARDINAL_DIR { NORTH, EAST, SOUTH, WEST, NORTH_EAST, SOUTH_EAST, SOUTH_WEST, NORTH_WEST }

# North (default, facing -Z)
const basis_north = Basis(Vector3.UP, deg_to_rad(0))
# East (90° yaw, facing +X)
const basis_east = Basis(Vector3.UP, deg_to_rad(90))
# South (180° yaw, facing +Z)
const basis_south = Basis(Vector3.UP, deg_to_rad(180))
# West (270° yaw, facing -X)
const basis_west = Basis(Vector3.UP, deg_to_rad(270))


func _ready() -> void:
	build_islands()
	Global.is_editing.connect(_on_is_editing)

func build_islands() -> void:
	var north_index: int = Grid.get_orthogonal_index_from_basis(basis_north)
	var east_index: int = Grid.get_orthogonal_index_from_basis(basis_east)
	var south_index: int = Grid.get_orthogonal_index_from_basis(basis_south)
	var west_index: int = Grid.get_orthogonal_index_from_basis(basis_west)
	for island in islands:
		var start_point: Vector3i = island.start_point
		var width: int = island.width
		var length: int = island.length
		for x in range(start_point.x, start_point.x + width + 1):
			for z in range(start_point.z, start_point.z + length + 1):
				var cell := Vector3i(x, 0, z)
				var direction: int = _get_cell_direction(cell, island)
				match direction:
					# corners
					CARDINAL_DIR.NORTH_WEST:
						Grid.set_cell_item(cell, MESH_INDEX.CORNER, west_index)
					CARDINAL_DIR.NORTH_EAST:
						Grid.set_cell_item(cell, MESH_INDEX.CORNER, north_index)
					CARDINAL_DIR.SOUTH_EAST:
						Grid.set_cell_item(cell, MESH_INDEX.CORNER, east_index)
					CARDINAL_DIR.SOUTH_WEST:
						Grid.set_cell_item(cell, MESH_INDEX.CORNER, south_index)
					# edges (non-corner)
					CARDINAL_DIR.NORTH:
						Grid.set_cell_item(cell, MESH_INDEX.EDGE, north_index)
					CARDINAL_DIR.EAST:
						Grid.set_cell_item(cell, MESH_INDEX.EDGE, east_index)
					CARDINAL_DIR.SOUTH:
						Grid.set_cell_item(cell, MESH_INDEX.EDGE, south_index)
					CARDINAL_DIR.WEST:
						Grid.set_cell_item(cell, MESH_INDEX.EDGE, west_index)
					# interior
					_:
						Grid.set_cell_item(cell, MESH_INDEX.CENTER)

func _get_cell_direction(cell: Vector3i, island: Dictionary) -> int:
	var x: int = cell.x
	var z: int = cell.z
	var start_point: Vector3i = island.start_point
	var width: int = island.width
	var length: int = island.length
	var on_north: bool = z == start_point.z
	var on_south: bool = z ==  start_point.z + length
	var on_east: bool = x == start_point.x
	var on_west: bool = x ==  start_point.x + width
	var direction: int
	if on_north and on_west:
		direction = CARDINAL_DIR.NORTH_WEST
	elif on_north and on_east:
		direction = CARDINAL_DIR.NORTH_EAST
	elif on_south and on_east:
		direction = CARDINAL_DIR.SOUTH_EAST
	elif on_south and on_west:
		direction = CARDINAL_DIR.SOUTH_WEST
	elif on_north:
		direction = CARDINAL_DIR.NORTH
	elif on_east:
		direction = CARDINAL_DIR.EAST
	elif on_south:
		direction = CARDINAL_DIR.SOUTH
	elif on_west:
		direction = CARDINAL_DIR.WEST
	else:
		direction = -1  # interior
	return direction

func _on_is_editing(is_editing):
	if is_editing:
		_show_overlay()
	else:
		_hide_overlay()

func _show_overlay():
	for island in islands:
		var start_point: Vector3i = island.start_point
		var width: int = island.width
		var length: int = island.length
		for x in range(start_point.x + 1, start_point.x + width):
			for z in range(start_point.z + 1, start_point.z + length):
				var cell = Vector3i(x, 1, z)
				Grid.set_cell_item(cell, MESH_INDEX.GRID_OVERLAY)

func _hide_overlay():
	for island in islands:
		var start_point: Vector3i = island.start_point
		var width: int = island.width
		var length: int = island.length
		for x in range(start_point.x + 1, start_point.x + width):
			for z in range(start_point.z + 1, start_point.z + length):
				var cell = Vector3i(x, 1, z)
				Grid.set_cell_item(cell, -1)
