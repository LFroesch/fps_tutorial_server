extends Node3D

var particles : Array[GPUParticles3D] = []

func _ready() -> void:
	for child in get_children():
		if child is GPUParticles3D:
			particles.append(child)
			child.finished.connect(particles_finished.bind(child))
			child.emitting = true
			
func particles_finished(particle : GPUParticles3D) -> void:
	particles.erase(particle)
	
	if particles.is_empty():
		queue_free()
