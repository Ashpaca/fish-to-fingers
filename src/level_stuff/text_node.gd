class_name TextNode extends Node3D

var MAX_DISTANCE_TO_PLAYER : float = 7.0
var MAX_PATH_LENGTH_TO_PLAYER : float = 12.0

@onready var text_box: RichLabel3D = $TextBox

func _ready() -> void:
	text_box.visible = false


func _physics_process(_delta: float) -> void:
	if GameState.current_state != GameState.MOVE:
		if GameState.reachable_text_nodes.has(self):
			GameState.reachable_text_nodes.erase(self)
			text_box.visible = false
		return
	
	var distance_to_player : float = (global_position - GameState.player_position).length()
	var path_length_to_player : float = MAX_PATH_LENGTH_TO_PLAYER + 9999 # just a big number.
	if distance_to_player < MAX_DISTANCE_TO_PLAYER:
		var map : RID = get_world_3d().navigation_map
		var optimize : bool = true
		var path : PackedVector3Array = NavigationServer3D.map_get_path(map, global_position, GameState.player_position, optimize)
		path_length_to_player = 0.0
		for i in range(1, len(path)):
			path_length_to_player += path[i].distance_to(path[i-1])
	
	if distance_to_player < MAX_DISTANCE_TO_PLAYER and path_length_to_player < MAX_PATH_LENGTH_TO_PLAYER:
		if not GameState.reachable_text_nodes.has(self):
			GameState.reachable_text_nodes.append(self)
			text_box.visible = true
	elif GameState.reachable_text_nodes.has(self):
		GameState.reachable_text_nodes.erase(self)
		text_box.visible = false
