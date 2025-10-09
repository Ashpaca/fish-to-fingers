extends Node

const TITLE_SCREEN : int = 0
const START_SERVER_SCREEN : int = 1
const JOIN_SERVER_SCREEN : int = 2
const PAUSE_MENU : int = 3
const SCENE_WAIT : int = 4
const WAIT_FOR_HOST : int = 5
const MOVE : int = 6
const LURE : int = 7
const REEL : int = 8
const HELPING_REEL : int = 9
const SCAVENGE : int = 10

var ALL_WORDS_LENGTH_3 : Array[String]
var ALL_WORDS_LENGTH_4 : Array[String]
var ALL_WORDS_LENGTH_5 : Array[String]
var ALL_WORDS_LENGTH_6 : Array[String]
var ALL_WORDS_LENGTH_7 : Array[String]

var current_state = TITLE_SCREEN

var port_number : int
var ipv6_number : String
var player_list : Array[Player] # not really using this. Only the host even has data here

var player_position : Vector3
var current_text : String
var other_players_text : String
var all_text_nodes : Array[TextNode]
var reachable_text_nodes : Array[TextNode]
var scavenge_letter_bag : Array[String] = ["e","e","e","e","e","e","e","e","e","e","e","e","a","a",
"a","a","a","a","a","a","a","i","i","i","i","i","i","i","i","i","o","o","o","o","o","o","o","o","n",
"n","n","n","n","n","r","r","r","r","r","r","t","t","t","t","t","t","l","l","l","l","s","s","s","s",
"u","u","u","u","d","d","d","d","g","g","g","b","b","c","c","m","m","p","p","f","f","h","h","v","v",
"w","w","y","y","k","j","x","q","z"]
var inventory_contents : Array[InventoryItem] = [null,null,null,null,null,null,null,null,null,null]
var inventory_slot_selected : int = 0

var activity_tracker : Dictionary = {"has_scavenged" : false}
var tutorial_complete : bool = false
var tutorial_failed : bool = false


func change_state(new_state : int) -> bool:
	if current_state == new_state:
		return false
	current_state = new_state
	EventBus.state_changed.emit()
	return true


func reset_game() -> void:
	get_tree().root.get_node("Main").add_child(load("res://src/level_stuff/game.tscn").instantiate())
	all_text_nodes = []
	reachable_text_nodes = []
	player_list = []
	tutorial_complete = false
	tutorial_complete = false


func add_item_to_inventory(item : InventoryItem) -> void:
	for i in range(inventory_contents.size()):
		if inventory_contents[i] == null:
			inventory_contents[i] = item.duplicate()
			EventBus.inventory_changed.emit()
			return
	print("oh no, no space!")


func is_inventory_item_selected_a_fish() -> bool:
	return inventory_contents[inventory_slot_selected] and inventory_contents[inventory_slot_selected].category == "fish"


func is_playing() -> bool:
	return current_state == MOVE or current_state == LURE or current_state == REEL or current_state == HELPING_REEL or current_state == SCAVENGE


func is_using_typing_agent() -> bool:
	return current_state == MOVE or current_state == LURE or current_state == REEL or current_state == HELPING_REEL


func change_state_to_lure(_node : FishingNode) -> void:
	change_state(LURE)


# parameters need to match the signal. So a second one is needed
func change_state_to_lure_2() -> void:
	change_state(LURE)


func change_state_to_reel(_fish : Fish) -> void:
	change_state(REEL)


func change_state_to_scavenge() -> void:
	change_state(SCAVENGE)
	#activity_tracker["has_scavenged"] = true


func _on_tutorial_complete() -> void:
	tutorial_complete = true


func _on_tutorial_failed() -> void:
	tutorial_failed = true


func _on_fillet_held_fish() -> void:
	for letter in inventory_contents[inventory_slot_selected].item_name:
		scavenge_letter_bag.append(letter)
	inventory_contents[inventory_slot_selected] = null
	EventBus.inventory_changed.emit()


func _ready() -> void:
	EventBus.start_fishing_at_node.connect(change_state_to_lure)
	EventBus.stop_reeling.connect(change_state_to_lure_2)
	EventBus.start_reeling_fish.connect(change_state_to_reel)
	EventBus.start_scavenging.connect(change_state_to_scavenge)
	EventBus.tutorial_complete.connect(_on_tutorial_complete)
	EventBus.tutorial_failed.connect(_on_tutorial_failed)
	EventBus.fillet_held_fish.connect(_on_fillet_held_fish)
	
	var allWordsFile : FileAccess = FileAccess.open("res://assets/word_lists/enable1.txt", FileAccess.READ)
	while not allWordsFile.eof_reached():
		var line : String = allWordsFile.get_line()
		match len(line):
			3:
				ALL_WORDS_LENGTH_3.append(line)
			4:
				ALL_WORDS_LENGTH_4.append(line)
			5:
				ALL_WORDS_LENGTH_5.append(line)
			6:
				ALL_WORDS_LENGTH_6.append(line)
			7:
				ALL_WORDS_LENGTH_7.append(line)
	
	var badWords : FileAccess = FileAccess.open("res://assets/word_lists/bad-words.txt", FileAccess.READ)
	while not badWords.eof_reached():
		var line : String = badWords.get_line()
		match len(line):
			3:
				ALL_WORDS_LENGTH_3.erase(line)
			4:
				ALL_WORDS_LENGTH_4.erase(line)
			5:
				ALL_WORDS_LENGTH_5.erase(line)
			6:
				ALL_WORDS_LENGTH_6.erase(line)
			7:
				ALL_WORDS_LENGTH_7.erase(line)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if current_state == LURE:
			change_state(MOVE)
			EventBus.stop_fishing.emit()
		elif current_state == REEL or current_state == HELPING_REEL:
			change_state(LURE)
			EventBus.stop_reeling.emit()
		elif current_state == SCAVENGE:
			change_state(MOVE)
			EventBus.stop_scavenging.emit()
