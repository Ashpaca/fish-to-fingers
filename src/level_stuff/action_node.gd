class_name ActionNode extends TextNode

@export var node_type : ActionNodeData

func on_typed() -> void:
	if node_type.signal_to_call == "": return
	if node_type.signal_arguments.size() > 0:
		EventBus.emit_signal(node_type.signal_to_call, node_type.signal_arguments)
	else:
		EventBus.emit_signal(node_type.signal_to_call)


# if node_type.additional_conditions is not empty then it should be a boolean expression to decide if the textbox should show
# example: "GameState.player_list.size() > 0"
# effect: only the host will have this node ever show, as currently only they get players added to the player_list
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if text_box.visible and not node_type.additional_conditions == "":
		var additional_check : Expression = Expression.new()
		additional_check.parse(node_type.additional_conditions, ["GameState"])
		if not additional_check.execute([GameState], self):
			text_box.visible = false
			GameState.reachable_text_nodes.erase(self)


func _ready() -> void:
	super._ready()
	MAX_DISTANCE_TO_PLAYER = node_type.activation_distance
	MAX_PATH_LENGTH_TO_PLAYER = node_type.activation_path_length
	text_box.text = node_type.node_text
