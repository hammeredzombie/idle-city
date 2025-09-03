extends GridMap
class_name Island

const max_grid_count: int = 5

@onready var Grid: GridMap = self

enum MESH_INDEX { CENTER, EDGE, OUT_CORNER, IN_CORNER }
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
	_build_islands()

func _build_islands() -> void:
	var north_index: int = Grid.get_orthogonal_index_from_basis(basis_north)
	var east_index: int = Grid.get_orthogonal_index_from_basis(basis_east)
	var south_index: int = Grid.get_orthogonal_index_from_basis(basis_south)
	var west_index: int = Grid.get_orthogonal_index_from_basis(basis_west)
	for x in range(-max_grid_count, max_grid_count):
		for z in range(-max_grid_count, max_grid_count):
			var cell := Vector3i(x, 0, z)
			var on_north: bool = z == -max_grid_count
			var on_south: bool = z ==  max_grid_count - 1
			var on_east: bool = x == -max_grid_count
			var on_west: bool = x ==  max_grid_count - 1
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
			match direction:
				# corners
				CARDINAL_DIR.NORTH_WEST:
					Grid.set_cell_item(cell, MESH_INDEX.OUT_CORNER, west_index)
				CARDINAL_DIR.NORTH_EAST:
					Grid.set_cell_item(cell, MESH_INDEX.OUT_CORNER, north_index)
				CARDINAL_DIR.SOUTH_EAST:
					Grid.set_cell_item(cell, MESH_INDEX.OUT_CORNER, east_index)
				CARDINAL_DIR.SOUTH_WEST:
					Grid.set_cell_item(cell, MESH_INDEX.OUT_CORNER, south_index)
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
				
