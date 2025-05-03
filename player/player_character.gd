extends CharacterBody3D
class_name PlayerCharacter

const HEALTH_GRADIENT := preload("res://player/player_info/health_gradient.tres")

@export var weapon_holder : WeaponHolder
@export var health_bar : ProgressBar

var health_bar_fill_style_box : StyleBoxFlat

var team : int
var weapon_id : int

func _ready() -> void:
	instantiate_weapon()
	if health_bar != null:
		health_bar_fill_style_box = health_bar.get_theme_stylebox("fill")
		update_health_bar(1, 1, 0)
	
func instantiate_weapon() -> void:
	if weapon_holder == null:
		print("no weapon holder found on ", self)
		
	weapon_holder.instantiate_weapon(weapon_id)

func update_health_bar(current_health : int, max_health : int, changed_amount: int) -> void:
	if health_bar == null:
		return
		
	var new_value := current_health / float(max_health)
	health_bar.value = new_value
	health_bar_fill_style_box.bg_color = HEALTH_GRADIENT.gradient.sample(new_value)
