class_name Player extends CharacterBody3D

const CAMERA_OFFSET : Vector3 = Vector3(0, 3.4, 2.4)
const SPEED = 2.5

# these are used by the other player
@export var my_current_text : String = ""
@export var my_current_animation : String = "cat walk"
@export var my_animation_is_playing : bool = false

@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var cat: Node3D = $Cat
@onready var cat_animator : AnimationPlayer = $Cat/AnimationPlayer

var spawn_location : Vector3 = Vector3.ZERO
var rotation_goal : float = -PI

func move_to_location():
	var direction : Vector3 = (nav_agent.get_next_path_position() - global_position).normalized()
	_on_new_rotation_goal(atan2(direction.x, direction.z))
	velocity = direction * SPEED + velocity.y * Vector3.UP


func rotate_player_model(delta : float) -> void:
	var max_angle = PI * 2
	var difference = fmod(rotation_goal - cat.rotation.y, max_angle)
	cat.rotation.y = cat.rotation.y + (fmod(2 * difference, max_angle) - difference) * delta * 3


# you update your text from the gamestate.
# godot updates this value on the other side
# grab this updated value and store it in gamestate
func update_players_typed_text() -> void:
	if is_multiplayer_authority():
		my_current_text = GameState.current_text
	else:
		GameState.other_players_text = my_current_text


func update_players_animation_state() -> void:
	if is_multiplayer_authority():
		my_current_animation = cat_animator.current_animation
		my_animation_is_playing = cat_animator.is_playing()
	else:
		if my_current_animation != cat_animator.current_animation or not cat_animator.is_playing():
			cat_animator.play(my_current_animation)
		if not my_animation_is_playing:
			cat_animator.pause()


# i still don't fully understand rpc calls I need to look into them more
@rpc("any_peer", "call_local")
func set_spawn(location : Vector3) -> void:
	spawn_location = location
	global_position = spawn_location
	nav_agent.target_position = spawn_location
	if is_multiplayer_authority():
		EventBus.connect_camera_to.emit(self, CAMERA_OFFSET)


func _on_new_rotation_goal(angle : float) -> void:
	rotation_goal = angle


func _on_go_to_node(node : TextNode) -> void:
	nav_agent.target_position = node.global_position
	cat_animator.play("cat walk")


func _on_start_fishing(node : FishingNode):
	if not is_multiplayer_authority(): return
	FishState.last_used_fishing_node = node
	cat_animator.play("cat lazy idle")


func _on_stop_fishing() -> void:
	if not is_multiplayer_authority(): return # do i need to check this?
	EventBus.connect_camera_to.emit(self, CAMERA_OFFSET)


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	EventBus.go_to_node.connect(_on_go_to_node)
	EventBus.update_player_rotation_goal.connect(_on_new_rotation_goal)
	EventBus.stop_fishing.connect(_on_stop_fishing)
	EventBus.start_fishing_at_node.connect(_on_start_fishing)
	cat_animator.play("cat walk")


func _physics_process(delta: float) -> void:
	if not GameState.is_playing(): return
	if not is_multiplayer_authority(): return
	
	if not is_on_floor():
		velocity += get_gravity() * delta * 20
		
	if (nav_agent.target_position - global_position).length() > 1.1: # only move to location when further than nav goal
		move_to_location()
	else:
		velocity = velocity.y * Vector3.UP
		if cat_animator.current_animation == "cat walk":
			cat_animator.call_deferred("pause")
	move_and_slide()
	rotate_player_model(delta)
	
	GameState.player_position = global_position


func _process(_delta: float) -> void:
	update_players_typed_text()
	update_players_animation_state()
