extends Node3D
class_name Lobby

const INTERPOLATION_BUFFER_MS := 100

var players := {}
var world_state_buffer : Array[Dictionary] = []
var pickups := {}
var grenades := {}

func get_local_player() -> PlayerLocal:
	return players.get(multiplayer.get_unique_id())

func get_remote_players() -> Dictionary:
	var remote_players := {}
	
	for client_id in players.keys():
		if client_id == multiplayer.get_unique_id():
			continue
		var maybe_remote_player : PlayerRemote = players.get(client_id)
		if is_instance_valid(maybe_remote_player):
			remote_players[client_id] = maybe_remote_player
	
	return remote_players

func _ready() -> void:
	add_to_group("Lobby")
	c_lock_client.rpc_id(1)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	send_player_state()
	handle_world_state()

func send_player_state() -> void:
	if get_local_player() == null:
		return
	c_send_player_state.rpc_id(1, create_player_data())

func create_player_data() -> Dictionary:
	var local_player := get_local_player()
	var player_state := {
		"pos" : local_player.position,
		"rot_y" : local_player.rotation.y,
		"anim" : local_player.current_anim,
		"rot_x" : local_player.head.rotation.x
	}
	return player_state

func handle_world_state() -> void:
	if world_state_buffer.size() < 2:
		return
	
	var target_render_unix_ms : int = floori(Time.get_unix_time_from_system() * 1000) - INTERPOLATION_BUFFER_MS - Server.clock_deviation_ms
	while world_state_buffer.size() > 2 and target_render_unix_ms > world_state_buffer[1].t:
		world_state_buffer.pop_front()
	
	var lerp_weight := remap(target_render_unix_ms, world_state_buffer[0].t, world_state_buffer[1].t, 0, 1)
	
	if world_state_buffer[0].has("gr") and world_state_buffer[1].has("gr"):
		handle_grenades(world_state_buffer[0].gr, world_state_buffer[1].gr, lerp_weight) 
	
	var remote_players := get_remote_players()
	
	if not world_state_buffer[0].has("ps") or not world_state_buffer[1].has("ps"):
		return
	
	for client_id in world_state_buffer[1].ps.keys():
		if not client_id in remote_players.keys():
			continue
		if not client_id in world_state_buffer[0].ps.keys():
			continue
		
		if not is_instance_valid(players.get(client_id)):
			continue
		
		var remote_player : PlayerRemote = remote_players.get(client_id)
		remote_player.update_body_geometry(
			world_state_buffer[0].ps.get(client_id),
			world_state_buffer[1].ps.get(client_id),
			lerp_weight
		)

func handle_grenades(old_grenade_data : Dictionary, new_grenade_data : Dictionary, lerp_weight : float) -> void:
	for grenade_name in new_grenade_data.keys():
		# maybe spawning new grenades
		if not grenade_name in grenades.keys():
			var grenade : Grenade = preload("res://player/grenade/grenade.tscn").instantiate()
			grenades[grenade_name] = {"inst" : grenade, "exploded" : false}
			grenade.name = grenade_name
			grenade.global_transform = new_grenade_data.get(grenade_name).tform
			add_child(grenade, true)
		
	for grenade_name in old_grenade_data.keys():
		# exploding the grenade if not in buffer anymore nad not exploded yet
		if not grenade_name in new_grenade_data.keys():
			if not grenade_name in grenades.keys():
				continue
				
			if not grenades.get(grenade_name).exploded:
				explode_grenade(grenade_name)
				grenades.erase(grenade_name)
				continue
		if grenades.get(grenade_name).exploded:
			continue
			
		# moving the grenades
		var grenade : Grenade = grenades.get(grenade_name).inst
		
		grenade.lerp_tform(old_grenade_data.get(grenade_name), new_grenade_data.get(grenade_name), lerp_weight)


# Make sure it arrives in right order, but can drop some packets here or there not game breaking
@rpc("any_peer", "call_remote", "unreliable_ordered")
func c_send_player_state(player_state : Dictionary) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func c_lock_client() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_loading_map() -> void:
	var map = load("res://maps/map_farm.tscn").instantiate()
	map.name = "Map"
	map.ready.connect(map_ready)
	add_child(map, true)
	get_tree().call_group("LocalGameSceneManager", "clear_scenes")

func map_ready() -> void:
	c_map_ready.rpc_id(1)
	
@rpc("any_peer", "call_remote", "reliable")
func c_map_ready() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func s_start_match() -> void:
	get_tree().call_group("PlayerLocal", "set_processes", true)
	set_physics_process(true)

@rpc("authority", "call_remote", "reliable")
func s_spawn_player(client_id: int, spawn_tform : Transform3D, team : int, player_name : String, weapon_id : int, auto_freeze : bool):
	var player : PlayerCharacter
	
	if client_id == multiplayer.get_unique_id():
		player = preload("res://player/local/player_local.tscn").instantiate()
		player.auto_freeze = auto_freeze
		
	else:
		player = preload("res://player/remote/player_remote.tscn").instantiate()
		player.display_name = player_name
	player.weapon_id = weapon_id
	player.team = team
	player.name = str(client_id)
	player.global_transform = spawn_tform
	add_child(player, true)
	players[client_id] = player

@rpc("authority", "call_remote", "unreliable_ordered")
func s_send_world_state(new_world_state : Dictionary) -> void:
	world_state_buffer.append(new_world_state)

@rpc("authority", "call_remote", "reliable")
func s_start_weapon_selection() -> void:
	get_tree().call_group("WeaponSelectionUI", "activate")

func weapon_selected(weapon_id : int) -> void:
	c_weapon_selected.rpc_id(1, weapon_id)

@rpc("any_peer", "call_remote", "reliable")
func c_weapon_selected(weapon_id : int) -> void:
	pass

func local_shot_fired() -> void:
	c_shot_fired.rpc_id(1, floori(Time.get_unix_time_from_system() * 1000) - Server.clock_deviation_ms, create_player_data())

@rpc("any_peer", "call_remote", "unreliable")
func c_shot_fired(time_stamp : int, player_data : Dictionary) -> void:
	pass
	
@rpc("authority", "call_remote", "unreliable")
func s_play_shoot_fx(target_client_id : int) -> void:
	var remote_players := get_remote_players()
	if not target_client_id in remote_players:
		return
	remote_players[target_client_id].play_shoot_fx()

@rpc("authority", "call_remote", "unreliable")
func s_spawn_bullet_hit_fx(pos: Vector3, normal : Vector3, type: int) -> void:
	var bullet_hit_fx : Node3D
	match type:
		0: #environment
			bullet_hit_fx = preload("res://player/bullet_hit_fx/bullet_hit_fx_environment.tscn").instantiate()
		1: #player
			bullet_hit_fx = preload("res://player/bullet_hit_fx/bullet_hit_fx_player.tscn").instantiate()
	var spawn_tform := Transform3D.IDENTITY
	
	if not normal.is_equal_approx(Vector3.UP) and not normal.is_equal_approx(Vector3.DOWN):
		spawn_tform = spawn_tform.looking_at(normal)
		spawn_tform = spawn_tform.rotated_local(Vector3.RIGHT, -PI/2)
		
	spawn_tform.origin = pos
	bullet_hit_fx.global_transform = spawn_tform
	add_child(bullet_hit_fx)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_health(target_client_id : int, current_health : int, max_health : int, changed_amount: int) -> void:
	var maybe_player : PlayerCharacter = players.get(target_client_id)
	if is_instance_valid(maybe_player):
		maybe_player.update_health_bar(current_health, max_health, changed_amount)

@rpc("authority", "call_remote", "reliable")
func s_spawn_pickup(pickup_name : String, pickup_type : int, pos : Vector3) -> void:
	var pickup : Pickup = preload("res://player/pickups/pickup.tscn").instantiate()
	pickup.name = pickup_name
	pickup.position = pos
	pickup.pickup_type = pickup_type
	add_child(pickup, true)
	pickups[pickup.name] = pickup

@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_started(pickup_name : String) -> void:
	pickups.get(pickup_name).cooldown_started()
	
@rpc("authority", "call_remote", "reliable")
func s_pickup_cooldown_ended(pickup_name : String) -> void:
	pickups.get(pickup_name).cooldown_ended()

@rpc("authority", "call_remote", "reliable")
func s_player_died(dead_player_id : int) -> void:
	if players.has(dead_player_id):
		players.get(dead_player_id).queue_free()
		players[dead_player_id] = null

@rpc("authority", "call_remote", "reliable")
func s_update_game_scores(blue_score : int, red_score : int) -> void:
	get_tree().call_group("MatchInfoUI", "update_score", blue_score, red_score)

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_match_time_left(time_left : int) -> void:
	get_tree().call_group("MatchInfoUI", "update_match_time_left", time_left)

@rpc("authority", "call_remote", "reliable")
func s_end_match(end_client_data : Dictionary) -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/match_end_info/match_end_info_ui.tscn", end_client_data)
	queue_free()

func try_throw_grenade() -> void:
	c_try_throw_grenade.rpc_id(1, create_player_data())
	
@rpc("any_peer", "call_remote", "reliable")
func c_try_throw_grenade(player_state : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "unreliable_ordered")
func s_update_grenades_left(grenades_left : int) -> void:
	get_local_player().update_grenades_left(grenades_left)

@rpc("authority", "call_remote", "reliable")
func s_explode_grenade(grenade_name : String) -> void:
	pass

func explode_grenade(grenade_name : String) -> void:
	if not grenade_name in grenades.keys():
		return
		
	var grenade : Grenade = grenades.get(grenade_name).inst
	
	if is_instance_valid(grenade):
		var explosion_fx : Node3D = preload("res://player/grenade/grenade_explosion_fx.tscn").instantiate()
		explosion_fx.global_transform = grenade.global_transform
		add_child(explosion_fx)
		grenade.queue_free()
		
	grenades[grenade_name].exploded = true
