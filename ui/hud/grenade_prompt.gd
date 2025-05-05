extends Control
class_name GrenadePrompt

@onready var grenade_icon_texture_rect: TextureRect = $GrenadeIconTextureRect

func update_rotation(new_rot : float) -> void:
	rotation = new_rot
	grenade_icon_texture_rect.rotation = -new_rot
