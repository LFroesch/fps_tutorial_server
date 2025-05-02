extends Node3D
class_name WeaponHolder

var weapon : Weapon

func instantiate_weapon(weapon_id : int) -> void:
	match weapon_id:
		0: # pistol
			weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		1: # smg
			weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		2: # shotgun
			weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		
	add_child(weapon)
