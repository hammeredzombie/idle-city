extends GridMap
class_name Island

const max_grid_count: int = 5

@onready var Grid: GridMap = self

enum { CENTER, EDGE, OUT_CORNER, IN_CORNER }

func _ready() -> void:
    pass

func _build_island() -> void:
    for x in range(-max_grid_count, max_grid_count):
        for z in range(-max_grid_count, max_grid_count):
            var cell := Vector3i(x, 0, z)
            Grid.set_cell_item(cell, CENTER)