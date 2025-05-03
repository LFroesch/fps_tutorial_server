extends Control

@onready var blue_team_score_label: Label = %BlueTeamScoreLabel
@onready var red_team_score_label: Label = %RedTeamScoreLabel
@onready var minutes_left_label: Label = %MinutesLeftLabel
@onready var seconds_left_label: Label = %SecondsLeftLabel

func _ready() -> void:
	update_score(0,0)
	update_match_time_left(0)
	
func update_score(blue_score : int, red_score : int) -> void:
	blue_team_score_label.text = str(blue_score)
	red_team_score_label.text = str(red_score)

func update_match_time_left(time_left : int) -> void:
	var minutes_left := time_left / 60
	var seconds_left := time_left - minutes_left * 60
	minutes_left_label.text = str(minutes_left).lpad(2, "0")
	seconds_left_label.text = str(seconds_left).lpad(2, "0")
