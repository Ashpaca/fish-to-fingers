extends Node3D

@onready var screen_quad: MeshInstance3D = $ScreenQuad

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var player_scene : PackedScene = load("res://src/player/player.tscn")

func spawn_player(player : Player) -> void:
	add_child(player)
	player.set_spawn.rpc(Vector3(len(GameState.player_list) - 1.5 + 5, 0.1, 15))

func _on_start_server() -> void:
	peer.create_server(GameState.port_number)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player(1)


func _on_join_server() -> void:
	
	""" <- uncomment here for local testing
	peer.create_client(GameState.ipv6_number, GameState.port_number, 0, 0, 0, GameState.port_number)
	"""
	peer.create_client(GameState.ipv6_number, GameState.port_number, 0, 0, 0, GameState.port_number+1)# - different ports for local testing"""
	
	multiplayer.multiplayer_peer = peer
	multiplayer.server_disconnected.connect(_on_host_disconnected)


func _add_player(id : int) -> void:
	var player : Player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("spawn_player", player)
	GameState.player_list.append(player)


func _on_host_disconnected() -> void:
	GameState.change_state(GameState.TITLE_SCREEN)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit_game") and GameState.current_state == GameState.MOVE:
		GameState.change_state(GameState.TITLE_SCREEN)
		queue_free()
		peer.close()


func _ready() -> void:
	EventBus.connect("begin_start_server", _on_start_server)
	EventBus.connect("begin_join_server", _on_join_server)
	
	screen_quad.visible = true
