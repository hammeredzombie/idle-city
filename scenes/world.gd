extends Node3D

var islands_array: Array[Dictionary] = [
	{
		'start_point':Vector3i(-4,0,-4),
		'width': 10,
		'length': 10
	}
]

@onready var Islands: IslandBuilder = get_node('Islands')
@onready var Road: RoadBuilder = get_node('Road')

func _ready() -> void:
	Islands.islands = islands_array
	Islands.build_islands()
	Road.islands_array = islands_array
