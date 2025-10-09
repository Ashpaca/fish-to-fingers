class_name TypingAgent extends Node2D

const A : int = 65
const Z : int = 90
const BACKSPACE : int = 4194308
const SPACE : int = 32
const LOWERCASE_OFFSET : int = 32
const FONT_SIZE : int = 32
const OUTLINE_SIZE : int = 20

@onready var text_display : RichTextLabel = $TextDisplay

var number_of_matching_letters : int = 0
var text : String = ""

func _ready() -> void:
	clear_text_display()


func _process(_delta: float) -> void:
	if not GameState.is_playing(): return
	setup_text()
	GameState.current_text = text
	if GameState.current_state == GameState.MOVE:
		set_matching_letters(find_partial_match_node())
		if find_word_match_node():
			clear_text_display()
	elif GameState.current_state == GameState.LURE:
		if FishState.catchable_schoolers.is_empty():
			find_lure_match()
			clear_text_display()
		elif find_lure_match():
			clear_text_display()
		else:
			set_matching_letters(find_partial_match_schooler())
			if find_word_match_schooler():
				clear_text_display()
	elif GameState.current_state == GameState.REEL:
		if is_multiplayer_authority():
			set_matching_letters(find_partial_match_fish())
			if find_word_match_fish():
				clear_text_display()
		else:
			rpc("client_find_partial_match_fish")
			rpc("client_find_word_match_fish")
	elif GameState.current_state == GameState.HELPING_REEL:
		if is_multiplayer_authority():
			set_matching_letters(helping_find_partial_match_fish())
			if helping_find_word_match_fish():
				clear_text_display()
		else:
			rpc("helping_client_find_partial_match_fish")
			rpc("helping_client_find_word_match_fish")

func _input(event: InputEvent) -> void:
	if not GameState.is_using_typing_agent(): return
	if event is InputEventKey and event.is_pressed():
		if event.keycode >= A and event.keycode <= Z:
			text += String.chr(event.keycode + LOWERCASE_OFFSET)
		elif event.keycode == BACKSPACE and len(text) > 0:
			text = text.erase(len(text) - 1)
		elif event.keycode == SPACE and len(text) > 0:
			text += " "
		EventBus.letter_typed.emit(event.keycode)


func setup_text() -> void:
	var displayed_message = "[center]" + "[outline_size=" + str(OUTLINE_SIZE) + "]" + "[font_size=" + str(FONT_SIZE) + "]"
	
	for i in range(len(text)):
		if i < number_of_matching_letters:
			displayed_message += "[color=white]" + text[i] + "[/color]"
		else:
			displayed_message += "[color=red]" + text[i] + "[/color]"
	
	displayed_message +=   "[/font_size]" + "[/outline_size]" + "[/center]"
	
	if number_of_matching_letters < len(text):
		displayed_message = "[shake rate=20.0 level=" + str(4 + len(text) - number_of_matching_letters) + " connected=1]" + displayed_message + "[/shake]"
	
	text_display.text = displayed_message


# this may also need to be in game state. Not sure how I'll be handling this yet
func set_matching_letters(letter_count : int) -> void:
	number_of_matching_letters = letter_count
	

func clear_text_display() -> void:
	set_text("")


func set_text(new_text : String) -> void:
	text = new_text


func find_partial_match_node() -> int:
	for target in GameState.reachable_text_nodes:
		target.text_box.matched_letters(0, 0)
	
	for i in range(len(text), 0, -1):
		for target in GameState.reachable_text_nodes:
			if target.text_box.text.find(text.substr(0, i)) == 0:
				target.text_box.matched_letters(i, len(text))
				var direction : Vector3 = (target.global_position - GameState.player_position).normalized()
				EventBus.update_player_rotation_goal.emit(atan2(direction.x, direction.z))
				return i
	return 0


func find_word_match_node() -> bool:
	for target in GameState.reachable_text_nodes:
		if target.text_box.text == text:
			if target is not FishingNode and target is not ActionNode:
				EventBus.go_to_node.emit(target)
			elif target is FishingNode:
				EventBus.start_fishing_at_node.emit(target)
			elif target is ActionNode:
				if target.node_type.walk_when_typed:
					EventBus.go_to_node.emit(target)
				target.on_typed()
			return true
	return false


func find_lure_match() -> bool:
	if not text == "":
		if is_multiplayer_authority():
			EventBus.tried_to_lure.emit(text, GameState.player_position)
		else:
			rpc("client_lure_match", text, var_to_str(GameState.player_position))
	for fish in FishState.catchable_fish:
		if fish.qte_letter == text:
			fish.got_lured()
			return true
	return false


@rpc("call_remote", "any_peer")
func client_lure_match(letter : String, from_position : String) -> void:
	EventBus.tried_to_lure.emit(letter, str_to_var(from_position))


# TODO: Work out if this needs to be a rpc call or if client can just do this themself!!!
# mostly the same as find_partial_match_fish(), but using the other player's data
@rpc("any_peer", "call_remote")
func client_find_partial_match_fish() -> void:
	if not FishState.peers_lured_fish: return 
	var previous_word_lengths : int = 0
	for i in range(len(GameState.other_players_text), 0, -1):
		previous_word_lengths = 0
		for word in FishState.peers_lured_fish.word_list:
			if word.find(GameState.other_players_text.substr(0, i)) == 0:
				rpc("set_fish_matching_letters_from_host", i, len(GameState.other_players_text), previous_word_lengths)
				return
			previous_word_lengths += len(word) + 1
	rpc("set_fish_matching_letters_from_host", 0, 0, 0)


@rpc("authority", "call_remote")
func set_fish_matching_letters_from_host(match : int, length : int, skipped : int) -> void:
	if not FishState.lured_fish: return
	set_matching_letters(match)
	FishState.lured_fish.reeling_text_box.matched_letters(match, length, skipped)


func find_partial_match_fish() -> int:
	if not FishState.lured_fish: return 0
	var previous_word_lengths : int = 0
	for i in range(len(text), 0, -1):
		previous_word_lengths = 0
		for word in FishState.lured_fish.word_list:
			if word.find(text.substr(0, i)) == 0:
				FishState.lured_fish.reeling_text_box.matched_letters(i, len(text), previous_word_lengths)
				return i
			previous_word_lengths += len(word) + 1
	FishState.lured_fish.reeling_text_box.matched_letters(0, 0)
	return 0


@rpc("any_peer", "call_remote")
func client_find_word_match_fish() -> void:
	if not FishState.peers_lured_fish: return
	if GameState.other_players_text == "": return
	for i in range(len(FishState.peers_lured_fish.word_list)):
		if FishState.peers_lured_fish.word_list[i] == GameState.other_players_text:
			FishState.peers_lured_fish.clear_word_at_position(i)
			rpc("return_word_match_fish_from_host", true)
			return
	rpc("return_word_match_fish_from_host", false)


@rpc("authority", "call_remote")
func return_word_match_fish_from_host(found : bool) -> void:
	if found:
		clear_text_display()


func find_word_match_fish() -> bool:
	if not FishState.lured_fish: return false
	if text == "": return false
	for i in range(len(FishState.lured_fish.word_list)):
		if FishState.lured_fish.word_list[i] == text:
			FishState.lured_fish.clear_word_at_position(i)
			return true
	return false


func find_partial_match_schooler() -> int:
	for schooler in FishState.catchable_schoolers:
		schooler.word_box.matched_letters(0, 0)
	for i in range(len(text), 0, -1):
		for schooler in FishState.catchable_schoolers:
			if schooler.word_box.text.find(text.substr(0, i)) == 0:
				schooler.word_box.matched_letters(i, len(text))
				return i
	return 0


func find_word_match_schooler() -> bool:
	if text == "": return false
	for schooler in FishState.catchable_schoolers:
		if schooler.word_box.text == text:
			schooler.catch()
			return true
	return false


# ####
# Below are copied functions for the helping state. Could probably be combined with those above in some way
# Pretty much switched out lured_fish and peers_lured_fish in all places
# ####


@rpc("any_peer", "call_remote")
func helping_client_find_partial_match_fish() -> void:
	if not FishState.lured_fish: return 
	var previous_word_lengths : int = 0
	for i in range(len(GameState.other_players_text), 0, -1):
		previous_word_lengths = 0
		for word in FishState.lured_fish.word_list:
			if word.find(GameState.other_players_text.substr(0, i)) == 0:
				rpc("helping_set_fish_matching_letters_from_host", i, len(GameState.other_players_text), previous_word_lengths)
				return
			previous_word_lengths += len(word) + 1
	rpc("helping_set_fish_matching_letters_from_host", 0, 0, 0)


@rpc("authority", "call_remote")
func helping_set_fish_matching_letters_from_host(match : int, length : int, skipped : int) -> void:
	if not FishState.peers_lured_fish: return
	set_matching_letters(match)
	FishState.peers_lured_fish.reeling_text_box.matched_letters(match, length, skipped)


func helping_find_partial_match_fish() -> int:
	if not FishState.peers_lured_fish: return 0
	var previous_word_lengths : int = 0
	for i in range(len(text), 0, -1):
		previous_word_lengths = 0
		for word in FishState.peers_lured_fish.word_list:
			if word.find(text.substr(0, i)) == 0:
				FishState.peers_lured_fish.reeling_text_box.matched_letters(i, len(text), previous_word_lengths)
				return i
			previous_word_lengths += len(word) + 1
	FishState.peers_lured_fish.reeling_text_box.matched_letters(0, 0)
	return 0

@rpc("any_peer", "call_remote")
func helping_client_find_word_match_fish() -> void:
	if not FishState.lured_fish: return
	if GameState.other_players_text == "": return
	for i in range(len(FishState.lured_fish.word_list)):
		if FishState.lured_fish.word_list[i] == GameState.other_players_text:
			FishState.lured_fish.clear_word_at_position(i)
			rpc("helping_return_word_match_fish_from_host", true)
			return
	rpc("helping_return_word_match_fish_from_host", false)


@rpc("authority", "call_remote")
func helping_return_word_match_fish_from_host(found : bool) -> void:
	if found:
		clear_text_display()


func helping_find_word_match_fish() -> bool:
	if not FishState.peers_lured_fish: return false
	if text == "": return false
	for i in range(len(FishState.peers_lured_fish.word_list)):
		if FishState.peers_lured_fish.word_list[i] == text:
			FishState.peers_lured_fish.clear_word_at_position(i)
			return true
	return false
