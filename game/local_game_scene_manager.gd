extends Node


func _ready() -> void:
	change_scene("res://ui/main_menu/main_menu.tscn")
	
func change_scene(path_to_scene : String) -> void:
	clear_scenes()
	
	var new_scene = load(path_to_scene).instantiate()
	
	add_child(new_scene)
	
func clear_scenes() -> void:
	for child in get_children():
		child.queue_free()
