class_name Base
extends Node3D

# Ратуша занимает 3x3 клетки и стоит в конце пути
const SIZE_CELLS := 3.0

var _mesh: MeshInstance3D

func setup() -> void:
    var side := SIZE_CELLS * Constants.CELL_SIZE

    _mesh = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(side, side, side)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Constants.COLOR_BASE
    box.material = mat
    _mesh.mesh = box
    # низ куба стоит на земле
    _mesh.position.y = box.size.y / 2.0
    add_child(_mesh)
