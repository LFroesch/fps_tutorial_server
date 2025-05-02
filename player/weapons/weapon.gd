extends Node3D
class_name Weapon

@export var is_automatic := false
@export var shot_cooldown := 0.3

@onready var shoot_light: OmniLight3D = %ShootLight
@onready var shoot_particles: GPUParticles3D = %ShootParticles

func _ready() -> void:
	shoot_light.hide()
	shoot_particles.finished.connect(shoot_light.hide)
	
func play_shoot_fx() -> void:
	shoot_light.show()
	shoot_particles.emitting = true
