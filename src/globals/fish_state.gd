extends Node

var catchable_fish : Array[Fish]
var catchable_schoolers : Array[Schooler]
var last_used_fishing_node : FishingNode
var lured_fish : Fish
var peers_lured_fish : Fish
var can_join_catch : bool

func check_if_can_join() -> void:
	if GameState.current_state != GameState.LURE: 
		can_join_catch = false
		return
	if peers_lured_fish:
		var dist_to_player = (peers_lured_fish.global_position - GameState.player_position).length()
		if dist_to_player < peers_lured_fish.fish_type.qte_max_distance:
			can_join_catch = true
			return
	can_join_catch = false

@rpc("any_peer", "call_remote")
func remove_peers_peers_lured_fish() -> void:
	peers_lured_fish = null


func _on_stop_reeling() -> void:
	EventBus.connect_camera_to.emit(last_used_fishing_node, last_used_fishing_node.camera_offset, last_used_fishing_node.camera_angle)
	lured_fish = null
	rpc("remove_peers_peers_lured_fish")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		if can_join_catch and peers_lured_fish:
			GameState.change_state(GameState.HELPING_REEL)
			EventBus.start_helping_fish.emit(peers_lured_fish)
			peers_lured_fish.rpc("peer_joined_reeling")


func _physics_process(_delta: float) -> void:
	check_if_can_join()
	if GameState.current_state == GameState.HELPING_REEL and not peers_lured_fish:
		EventBus.stop_reeling.emit()


func _ready() -> void:
	EventBus.stop_reeling.connect(_on_stop_reeling)
