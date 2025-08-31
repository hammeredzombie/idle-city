extends Node3D

func _ready() -> void:
    var island = $Island
    island._build_island()