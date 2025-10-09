extends Node2D

const INVENTORY_SIZE : int = 10

var unselected_background_sprite : Texture2D = preload("res://assets/sprites/Scavenge/scavenge_slot.png")
var selected_background_sprite : Texture2D = preload("res://assets/sprites/Scavenge/scavenge_tile.png")
var slot_backgrounds : Array[Sprite2D]
var slot_items : Array[Sprite2D]
var selected_position : int = 0

func set_selected_position(position : int) -> void:
	GameState.inventory_slot_selected = position
	for i in range(slot_backgrounds.size()):
		if i == position:
			slot_backgrounds[i].texture = selected_background_sprite
		else:
			slot_backgrounds[i].texture = unselected_background_sprite

func update_inventory_items() -> void:
	for i in range(GameState.inventory_contents.size()):
		if GameState.inventory_contents[i]:
			slot_items[i].texture = load(GameState.inventory_contents[i].thumbnail_filepath)
		else:
			slot_items[i].texture = null


func _process(delta: float) -> void:
	if GameState.is_using_typing_agent():
		visible = true
	else:
		visible = false


func _input(event: InputEvent) -> void:
	if not GameState.is_using_typing_agent(): return
	if event is InputEventKey and event.is_pressed():
		if event.keycode >= 48 and event.keycode <= 57:
			# takes the keycode values and turns them into 0-9 indexes
			var inventory_position : int = posmod(event.keycode - 49, 10)
			set_selected_position(inventory_position)


func _ready() -> void:
	EventBus.inventory_changed.connect(update_inventory_items)
	
	for i in range(get_children().size()):
		if i < INVENTORY_SIZE:
			slot_backgrounds.append(get_child(i))
		else:
			slot_items.append(get_child(i))
	update_inventory_items()
	set_selected_position(0)
