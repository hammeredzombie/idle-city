extends GridMap

enum TILE_INDEX {GREEN, GREY, BLUE, YELLOW}

func _ready() -> void:
    # set_cell_item(Vector3i(0,0,0),2)
    # set_cell_item(Vector3i(1,0,0),2)
    set_cell_item(Vector3i(0,0,1),2)
    set_cell_item(Vector3i(1,0,1),2)

