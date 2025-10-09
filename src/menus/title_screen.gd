extends CanvasLayer


func _ready() -> void:
	EventBus.connect("state_changed", _on_state_changed)


func _process(_delta: float) -> void:
	if GameState.current_state != GameState.TITLE_SCREEN: return


# I'm not sure if this can just be thought of as multiplayer without a second person. But I'll try
func _on_start_solo_button_pressed() -> void:
	GameState.reset_game()
	GameState.change_state(GameState.MOVE)
	EventBus.begin_start_server.emit()


func _on_start_server_button_pressed() -> void:
	GameState.change_state(GameState.START_SERVER_SCREEN)


func _on_join_server_button_pressed() -> void:
	GameState.change_state(GameState.JOIN_SERVER_SCREEN)


func _on_state_changed() -> void:
	visible = GameState.current_state == GameState.TITLE_SCREEN
