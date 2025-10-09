class_name Schooler extends CharacterBody3D

@export var fish_type : FishData:
	set(new_fish):
		fish_type = new_fish
		call_deferred("set_fish")
@export var removed : bool = false

@onready var hitbox: CollisionShape3D = $Hitbox
@onready var hitbox_shape : CapsuleShape3D = CapsuleShape3D.new()
@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var word_box: RichLabel3D = $WordBox

var places_to_swim : Array[Vector3]
var number_of_places_swum : int = 0
var fish_mesh: Node3D
var animation_player : AnimationPlayer
var rotation_goal : float
var deletion_timer : float = 0.0

func set_fish():
	hitbox_shape.radius = fish_type.radius
	hitbox_shape.height = fish_type.length
	hitbox.shape = hitbox_shape
	
	if fish_mesh:
		fish_mesh.queue_free()
	var new_fish_mesh = load(fish_type.mesh_file_path).instantiate()
	add_child(new_fish_mesh)
	fish_mesh = new_fish_mesh
	fish_mesh.position = Vector3.ZERO
	fish_mesh.scale = fish_type.mesh_scale * Vector3(1, 1, 1)
	animation_player = fish_mesh.get_node("AnimationPlayer")
	animation_player.play("BrownFish")
	if is_multiplayer_authority():
		call_deferred("rpc", "sync_fish", var_to_str(fish_type))


@rpc("call_remote")
func sync_fish(type : String) -> void:
	fish_type = str_to_var(type)
	set_fish()


func remove_fish() -> void:
	if is_multiplayer_authority():
		removed = true
	else:
		if not removed:
			rpc("request_host_remove_fish")


@rpc("any_peer", "call_remote")
func request_host_remove_fish() -> void:
	if not removed:
		remove_fish()


func start_swimming() -> void:
	number_of_places_swum = 0
	nav_agent.target_position = places_to_swim[0]


func check_for_deletion(delta: float) -> void:
	if not removed: return
	visible = false
	hitbox.disabled = true
	FishState.catchable_schoolers.erase(self)
	if is_multiplayer_authority():
		global_position = Vector3.UP * 100
		deletion_timer += delta
		if deletion_timer > 5:
			queue_free()


func update_catchable_schoolers_list() -> void:
	if GameState.current_state == GameState.LURE and (global_position - GameState.player_position).length() < fish_type.qte_max_distance:
		if not FishState.catchable_schoolers.has(self):
			FishState.catchable_schoolers.append(self)
		word_box.visible = true
	else:
		FishState.catchable_schoolers.erase(self)
		word_box.visible = false


func handle_swimming(delta: float) -> void:
	if (nav_agent.target_position - global_position).length() > 1.1:
		var direction : Vector3 = (nav_agent.get_next_path_position() - global_position).normalized()
		velocity = direction * fish_type.speed
		rotation_goal = atan2(-direction.x, -direction.z)
		rotate_to_goal(delta)
	elif number_of_places_swum + 1 < len(places_to_swim):
		number_of_places_swum += 1
		nav_agent.target_position = places_to_swim[number_of_places_swum]
	else:
		remove_fish()


func rotate_to_goal(delta : float) -> void:
	var max_angle = PI * 2
	var difference = fmod(rotation_goal - rotation.y, max_angle)
	rotation.y = rotation.y + (fmod(2 * difference, max_angle) - difference) * delta * 3


func catch() -> void:
	GameState.add_item_to_inventory(fish_type.inventory_info)
	remove_fish()


func _physics_process(delta: float) -> void:
	check_for_deletion(delta)
	if removed: return
	if not GameState.is_playing(): return
	update_catchable_schoolers_list()
	if not is_multiplayer_authority(): return
	handle_swimming(delta)
	move_and_slide()


func _ready() -> void:
	set_fish()
