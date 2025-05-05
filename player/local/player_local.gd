extends PlayerCharacter
class_name PlayerLocal

const IDLE_ANIM := "Idle"
const AIR_ANIM := "Jump_Idle"
const WALK_ANIM := "Walk_Shoot"
const RUN_ANIM := "Run_Shoot"

@export var grenade_amount_label : Label
@export var normal_speed := 3.0
@export var sprint_speed := 5.0
@export var jump_velocity := 4.0
@export var gravity := 0.2
@export var mouse_sensitivity := 0.005

@onready var head: Node3D = $Head

var auto_freeze := false
var is_grounded := true
var is_sprinting := false
var current_anim : String
var nearby_grenades : Array[Grenade] = []

func _ready() -> void:
	super()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if auto_freeze:
		set_processes(false)

func set_processes(enabled : bool) -> void:
	set_process(enabled)
	set_physics_process(enabled)
	set_process_input(enabled)

func _physics_process(delta: float) -> void:
	move()
	choose_anim()
	check_shoot_input()
	check_throw_grenade_input()
	show_nearby_grenades()

func move():
	if is_on_floor():
		is_sprinting = Input.is_action_pressed("sprint")
	
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	
		if not is_grounded:
			is_grounded = true
	
	else:
		velocity.y -= gravity
	
		if is_grounded:
			is_grounded = false
	
	var speed := normal_speed if not is_sprinting else sprint_speed
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.z = direction.z * speed
	velocity.x = direction.x * speed
	
	move_and_slide()

func choose_anim() -> void:
	if not is_grounded:
		current_anim = AIR_ANIM
		return
	if velocity.x or velocity.z:
		current_anim = RUN_ANIM if is_sprinting else WALK_ANIM
		return
	current_anim = IDLE_ANIM

func check_shoot_input() -> void:
	if Input.is_action_just_pressed("shoot"):
		weapon_holder.start_trigger_press()
	elif Input.is_action_just_released("shoot"):
		weapon_holder.end_trigger_press()

func check_throw_grenade_input() -> void:
	if Input.is_action_just_pressed("throw_grenade"):
		get_tree().call_group("Lobby", "try_throw_grenade")

func show_nearby_grenades() -> void:
	var grenades_data := {}
	var own_pos := Vector2(global_position.x, global_position.z)
	
	for grenade in nearby_grenades:
		var grenade_pos := Vector2(grenade.global_position.x, grenade.global_position.z)
		grenades_data[grenade.name] = own_pos.angle_to_point(grenade_pos) + PI / 2 + rotation.y
		
	get_tree().call_group("GrenadePromptsControl", "update_grenade_prompts", grenades_data)
	

func update_grenades_left(grenades_left : int) -> void:
	grenade_amount_label.text = str(grenades_left)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		look_around(event.relative)

func look_around(relative:Vector2):
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotate_x(-relative.y * mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x, -PI/2, PI/2)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_grenade_detection_area_3d_area_entered(area: Area3D) -> void:
	nearby_grenades.append(area.get_parent())

func _on_grenade_detection_area_3d_area_exited(area: Area3D) -> void:
	nearby_grenades.erase(area.get_parent())
