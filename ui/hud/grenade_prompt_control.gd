extends Control

var grenade_prompts := {}

func update_grenade_prompts(grenades_data : Dictionary) -> void:
	#delete old prompts
	for grenade_name in grenade_prompts.keys():
		if not grenade_name in grenades_data.keys():
			grenade_prompts.get(grenade_name).queue_free()
			grenade_prompts.erase(grenade_name)
			
	for grenade_name in grenades_data.keys():
		#create new prompts
		if not grenade_name in grenade_prompts.keys():
			var grenade_prompt : GrenadePrompt = preload("res://ui/hud/grenade_prompt.tscn").instantiate()
			grenade_prompts[grenade_name] = grenade_prompt
			add_child(grenade_prompt)
			
		grenade_prompts.get(grenade_name).update_rotation(grenades_data.get(grenade_name))
