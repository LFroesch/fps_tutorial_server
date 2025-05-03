extends Node


func _ready() -> void:
	change_scene("res://ui/main_menu/main_menu.tscn")
	
func change_scene(path_to_scene : String, maybe_extra_args = null) -> void:
	clear_scenes()
	
	var new_scene = load(path_to_scene).instantiate()
	
	add_child(new_scene)
	if new_scene is MatchEndInfoUI and maybe_extra_args is Dictionary:
		new_scene.show_score_infos(maybe_extra_args)
	
func clear_scenes() -> void:
	for child in get_children():
		child.queue_free()
