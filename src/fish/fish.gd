class_name Fish extends CharacterBody3D

signal fish_removed(used_letter : String)

const LURE_COOLDOWN : float = 1

@export var fish_type : FishData:
	set(new_fish):
		fish_type = new_fish
		call_deferred("set_fish")
@export var catchable : bool = false
@export var removed : bool = false
@export var is_lured : bool = false
@export var client_luring_me : bool = false

@onready var hitbox: CollisionShape3D = $Hitbox
@onready var hitbox_shape : CapsuleShape3D = CapsuleShape3D.new()
@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var qte_box: RichLabel3D = $QteBox
@onready var reeling_text_box: RichLabel3D = $ReelingTextBox
@onready var line_attach_point: Node3D = $LineAttachPoint

var water_body_im_in : String
var places_to_swim : Array[Vector3]
var number_of_places_swum : int = 0
var fish_mesh: Node3D
var animation_player : AnimationPlayer
var rotation_goal : float
var struggle_rotation : float
var qte_letter : String
var qte_timer : float = 0.0
var reel_timer : float = 0.0
var deletion_timer : float = 0.0
var word_list : Array[String]
var has_helping_timer_reset_been_used : bool = false

func determine_catchablity(delta: float) -> void:
	if is_lured:
		catchable = false 
		return
	qte_timer += delta
	if catchable and qte_timer > fish_type.qte_lenght:
		qte_timer = 0
		catchable = false
	elif randf() < fish_type.lure_probability and qte_timer > LURE_COOLDOWN:
		qte_timer = 0
		catchable = true

func start_swimming() -> void:
	number_of_places_swum = 0
	nav_agent.target_position = places_to_swim[0]


func rotate_to_goal(delta : float) -> void:
	var max_angle = PI * 2
	var difference = fmod(rotation_goal + struggle_rotation - rotation.y, max_angle)
	rotation.y = rotation.y + (fmod(2 * difference, max_angle) - difference) * delta * 3


func set_fish():
	qte_box.text = qte_letter
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
		call_deferred("rpc", "sync_fish", var_to_str(fish_type), qte_letter)


@rpc("call_remote")
func sync_fish(type : String, used_letter : String) -> void:
	fish_type = str_to_var(type)
	qte_letter = used_letter
	set_fish()


func remove_fish() -> void:
	if is_multiplayer_authority():
		fish_removed.emit(qte_letter)
		removed = true
	else:
		if not removed:
			rpc("request_host_remove_fish")


@rpc("any_peer", "call_remote")
func request_host_remove_fish() -> void:
	if not removed:
		remove_fish()


func got_lured() -> void: 
	if is_lured: return
	if is_multiplayer_authority():
		is_lured = true
		catchable = false
		set_reel_text()
		nav_agent.target_position = GameState.player_position
		EventBus.start_reeling_fish.emit(self)
		rpc("set_my_and_peers_lured_fish", false)
	elif not removed:
		GameState.change_state(GameState.WAIT_FOR_HOST)
		rpc("request_host_lure_fish", GameState.player_position)


@rpc("any_peer", "call_remote")
func request_host_lure_fish(player_pos : Vector3) -> void:
	if is_lured:
		rpc("lure_fish_confirmation", false)
	else:
		client_luring_me = true
		is_lured = true
		catchable = false
		set_reel_text()
		nav_agent.target_position = player_pos
		rpc("lure_fish_confirmation", true)


@rpc("authority", "call_remote")
func lure_fish_confirmation(successful : bool) -> void:
	if successful:
		rpc("set_my_and_peers_lured_fish", true)
		EventBus.start_reeling_fish.emit(self)
	else:
		GameState.change_state(GameState.LURE)


func clear_word_at_position(pos : int) -> void:
	if not pos < len(word_list): return
	word_list[pos] = ""
	set_reel_text()
	reel_timer = 0
	rpc("reset_clients_reel_timer")


@rpc("authority", "call_remote")
func reset_clients_reel_timer():
	reel_timer = 0.0


func check_if_caught() -> void:
	for symbol in reeling_text_box.text:
		if not symbol == "\\":
			return
	# no words, then you're caught
	GameState.add_item_to_inventory(fish_type.inventory_info)
	remove_fish()
	EventBus.stop_reeling.emit() # should I add a new signal?


# if removed is true, then the fish will move away and stop interacting
# after 5 seonds, it will actually delete.
# this gives time for any signals to be sent between the users
func check_for_deletion(delta: float) -> void:
	if not removed: return
	visible = false
	hitbox.disabled = true
	FishState.catchable_fish.erase(self)
	if is_multiplayer_authority():
		global_position = Vector3.UP * 100
		deletion_timer += delta
		if deletion_timer > 5:
			queue_free()


@rpc("any_peer", "call_local")
func set_my_and_peers_lured_fish(is_clients_fish : bool) -> void:
	if is_multiplayer_authority() != is_clients_fish:
		FishState.lured_fish = self
	else:
		FishState.peers_lured_fish = self


func set_reel_text() -> void:
	var temp_text : String = ""
	for word in word_list:
		temp_text += word + "\\"
	reeling_text_box.text = temp_text


func update_catchable_fish_list() -> void:
	if GameState.current_state == GameState.LURE and catchable and (global_position - GameState.player_position).length() < fish_type.qte_max_distance:
		if not FishState.catchable_fish.has(self):
			FishState.catchable_fish.append(self)
		qte_box.visible = true
	else:
		FishState.catchable_fish.erase(self)
		qte_box.visible = false


# true on client side when client is reeling the fish, and true on host side when they are
func is_lured_by_this_player() -> bool:
	return is_lured and is_multiplayer_authority() != client_luring_me


@rpc("any_peer", "call_remote")
func peer_joined_reeling() -> void:
	if has_helping_timer_reset_been_used: return
	has_helping_timer_reset_been_used = true
	reel_timer = 0.0


func _on_stop_reeling() -> void:
	if not is_lured: return
	if is_multiplayer_authority() and not client_luring_me:
		catchable = false
		qte_timer = -5
		reel_timer = 0
		is_lured = false
		struggle_rotation = 0.0
		nav_agent.target_position = places_to_swim[number_of_places_swum]
	elif not is_multiplayer_authority() and client_luring_me:
		reel_timer = 0
		rpc("request_host_stop_reeling")


@rpc("any_peer", "call_remote")
func request_host_stop_reeling() -> void:
	catchable = false
	qte_timer = -5
	is_lured = false
	struggle_rotation = 0.0
	nav_agent.target_position = places_to_swim[number_of_places_swum]
	client_luring_me = false


func handle_reeling_swimmming(delta : float) -> void:
	if (nav_agent.get_final_position() - global_position).length() > 1.1:
		var direction : Vector3 = (nav_agent.get_next_path_position() - global_position).normalized()
		velocity = direction * fish_type.speed
		rotation_goal = atan2(direction.x, direction.z)
	else:
		velocity = Vector3.ZERO
	rotate_to_goal(delta)


func handle_normal_swimming(delta : float) -> void:
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


func do_struggling(struggle_time : float) -> void:
	if not is_lured: return
	if is_multiplayer_authority():
		struggle_rotation = sin(struggle_time * 10)
	elif not removed:
		rpc("request_host_do_struggling", struggle_time)


@rpc("any_peer", "call_remote")
func request_host_do_struggling(struggle_time : float) -> void:
	do_struggling(struggle_time)


func _on_stop_spawning(water_body_name : String) -> void:
	if water_body_im_in == water_body_name:
		number_of_places_swum = len(places_to_swim) - 1
		nav_agent.target_position = places_to_swim[number_of_places_swum]


func _on_lure_attempt(letter : String, from_position : Vector3) -> void:
	if not catchable and letter == qte_letter and (global_position - from_position).length() < fish_type.qte_max_distance:
		qte_timer = 0


func _physics_process(delta: float) -> void:
	check_for_deletion(delta)
	if removed: return
	if not GameState.is_playing(): return
	update_catchable_fish_list()
	reeling_text_box.visible = is_lured_by_this_player() or (is_lured and GameState.current_state == GameState.HELPING_REEL)
	if is_lured_by_this_player():
		reel_timer += delta
		if reel_timer > fish_type.escape_time:
			EventBus.stop_reeling.emit()
		elif reel_timer > fish_type.struggle_time:
			do_struggling(reel_timer)
		check_if_caught()
	if is_lured and is_lured_by_this_player():
		EventBus.my_fishing_rod_state.emit(line_attach_point.global_position)
	elif is_lured and not is_lured_by_this_player():
		EventBus.peer_fishing_rod_state.emit(line_attach_point.global_position)
	
	if not is_multiplayer_authority(): return
	if is_lured:
		handle_reeling_swimmming(delta)
	else:
		handle_normal_swimming(delta)
	
	move_and_slide()
	determine_catchablity(delta)

func _ready() -> void:
	EventBus.tried_to_lure.connect(_on_lure_attempt)
	EventBus.stop_reeling.connect(_on_stop_reeling)
	EventBus.stop_spawning_regular_fish.connect(_on_stop_spawning)
	set_fish()
