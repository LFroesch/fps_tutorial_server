extends Node3D
class_name Grenade

func lerp_tform(old_data : Dictionary, new_data : Dictionary, lerp_weight : float) -> void:
	transform = old_data.tform.interpolate_with(new_data.tform, lerp_weight)
	
