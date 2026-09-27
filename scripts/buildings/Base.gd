class_name Base
extends Node3D

var _mesh: MeshInstance3D

func setup() -> void:
    _mesh = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(
        3.0 * Constants.CELL_SIZE,
        3.0 * Constants.CELL_SIZE,
        3.0 * Constants.CELL_SIZE
    )
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Constants.COLOR_BASE
    box.material = mat
    _mesh.mesh = box
    _mesh.position.y = 3.0    # центр куба на высоте 3 м (низ на y=0)
    add_child(_mesh)