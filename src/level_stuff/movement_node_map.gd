extends GridMap

var text_node_scene : PackedScene = preload("res://src/level_stuff/text_node.tscn")

func setup_nodes() -> void:
	for cell in get_used_cells():
		var node : TextNode = text_node_scene.instantiate()
		get_parent().add_child(node) 
		node.global_position = Vector3(0.5*cell.x + 0.25, cell.y + 0.25, 0.5*cell.z + 0.25) # .25 gets the center of the cell
		
		var usedWords : Array[String]
		for other_node in GameState.all_text_nodes:
			if (global_position - other_node.global_position).length() < node.MAX_DISTANCE_TO_PLAYER * 2:
				usedWords.append(other_node.text_box.text)
		var node_word = GameState.ALL_WORDS_LENGTH_3[randi_range(0, len(GameState.ALL_WORDS_LENGTH_3) - 1)]
		while node_word in usedWords:
			node_word = GameState.ALL_WORDS_LENGTH_3[randi_range(0, len(GameState.ALL_WORDS_LENGTH_3) - 1)]
		node.text_box.text = node_word
		GameState.all_text_nodes.append(node)

func _ready() -> void:
	call_deferred("setup_nodes")
