extends Control
class_name MatchEndInfoUI

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var blue_team_player_info_container: VBoxContainer = %BlueTeamPlayerInfoContainer
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var red_team_player_info_container: VBoxContainer = %RedTeamPlayerInfoContainer

var player_info_row_container_scene := preload("res://ui/match_end_info/player_info_row_container.tscn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func show_score_infos(client_data : Dictionary) -> void:
	var blue_score := 0
	var red_score := 0
	for data in client_data.values():
		var player_info_row : PlayerInfoRowContainer = player_info_row_container_scene.instantiate()
		player_info_row.set_data(data.display_name, data.kills, data.deaths)
		
		var target_player_info_container : VBoxContainer
		
		if data.team == 0:
			red_score += data.deaths
			target_player_info_container = blue_team_player_info_container
		else:
			blue_score += data.deaths
			target_player_info_container = red_team_player_info_container
			
		target_player_info_container.add_child(player_info_row)
		
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)

func _on_exit_button_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
