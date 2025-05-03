extends Node3D
class_name Pickup

const READY_MATERIAL := preload("res://assets/materials/pickup_ready_material.tres")
const NOT_READY_MATERIAL := preload("res://assets/materials/pickup_not_ready_material.tres")

@onready var platform: CSGCylinder3D = %Platform
@onready var mesh_holder: Node3D = $MeshHolder

enum PickupTypes {
	Health,
	Grenade
}

var pickup_type : int

func _ready() -> void:
	match pickup_type:
		PickupTypes.Health:
			mesh_holder.add_child(load("res://assets/meshes/items/health.tscn").instantiate())
		PickupTypes.Grenade:
			mesh_holder.add_child(load("res://assets/meshes/items/grenade.tscn").instantiate())
			
func cooldown_started() -> void:
	platform.material = NOT_READY_MATERIAL
	mesh_holder.hide()
	
func cooldown_ended() -> void:
	platform.material = READY_MATERIAL
	mesh_holder.show()
