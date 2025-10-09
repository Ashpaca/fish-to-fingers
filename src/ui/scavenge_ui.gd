extends Node2D

const A : int = 65
const Z : int = 90
const LOWERCASE_OFFSET : int = 32
const BACKSPACE : int = 4194308

@onready var word_zone: Node2D = $WordZone
@onready var letter_zone: Node2D = $LetterZone
@onready var save_zone: Node2D = $SaveZone

var word_zone_letters : Array[ScavengeLetterTile]
var letter_zone_letters : Array[ScavengeLetterTile]
var save_zone_letters : Array[ScavengeLetterTile]
var save_zone_swap_index : int = 0

func find_free_spot_in_letter_zone() -> int:
	for i in range(letter_zone_letters.size()):
		if letter_zone_letters[i].get_letter() == "-":
			return i
	return -1


func find_and_remove_letter_from_letter_zone(letter : String) -> bool:
	for i in range(letter_zone_letters.size()):
		if letter_zone_letters[i].get_letter() == letter:
			letter_zone_letters[i].update_letter("-")
			return true
	return false


func find_free_spot_in_save_zone() -> int:
	for i in range(save_zone_letters.size()):
		if save_zone_letters[i].get_letter() == "-":
			return i
	return -1


func find_and_remove_letter_from_save_zone(letter : String) -> bool:
	for i in range(save_zone_letters.size()):
		if save_zone_letters[i].get_letter() == letter:
			save_zone_letters[i].update_letter("-")
			return true
	return false


func get_number_letters_typed() -> int:
	for i in range(word_zone_letters.size()):
		if word_zone_letters[i].get_letter() == "-":
			return i
	return word_zone_letters.size()


func _on_start_scavenging() -> void:
	visible = true
	for tile : ScavengeLetterTile in letter_zone_letters:
		if GameState.scavenge_letter_bag.size() > 0:
			var random_letter = GameState.scavenge_letter_bag.pick_random()
			GameState.scavenge_letter_bag.erase(random_letter)
			tile.update_letter(random_letter)


func _on_stop_scavenging() -> void:
	visible = false
	for i in range(letter_zone_letters.size()):
		if not letter_zone_letters[i].get_letter() == "-":
			GameState.scavenge_letter_bag.append(letter_zone_letters[i].get_letter())
	for tile in word_zone_letters:
		tile.update_letter("-")
	for tile in letter_zone_letters:
		tile.update_letter("-")

func _input(event: InputEvent) -> void:
	if not GameState.current_state == GameState.SCAVENGE: return
	if event is InputEventKey and event.is_pressed():
		if event.keycode >= A and event.keycode <= Z:
			var letter_typed = String.chr(event.keycode + LOWERCASE_OFFSET)
			# holding shift should save the tile rather than use it
			if Input.is_action_pressed("rotate_left") or Input.is_action_pressed("rotate_right"):
				var save_location : int = find_free_spot_in_save_zone()
				# there is space in the saved tiles zone
				if save_location > -1:
					# move the tile
					if find_and_remove_letter_from_letter_zone(letter_typed):
						save_zone_letters[save_location].update_letter(letter_typed)
						save_zone_swap_index = 0
				# saved tile zone is full
				else:
					var letter_to_swap : String = save_zone_letters[save_zone_swap_index].get_letter()
					# swap the tiles
					if find_and_remove_letter_from_letter_zone(letter_typed):
						save_zone_letters[save_zone_swap_index].update_letter(letter_typed)
						letter_zone_letters[find_free_spot_in_letter_zone()].update_letter(letter_to_swap)
						save_zone_swap_index = (save_zone_swap_index + 1) % save_zone_letters.size()
					elif  find_and_remove_letter_from_save_zone(letter_typed):
						save_zone_letters[save_zone_swap_index].update_letter(letter_typed)
						save_zone_letters[find_free_spot_in_save_zone()].update_letter(letter_to_swap)
						save_zone_swap_index = (save_zone_swap_index + 1) % save_zone_letters.size()
			# if space move the tile to the word. Checking saved tiles second
			else:
				if get_number_letters_typed() < word_zone_letters.size():
					if find_and_remove_letter_from_letter_zone(letter_typed):
						word_zone_letters[get_number_letters_typed()].update_letter(letter_typed)
					elif find_and_remove_letter_from_save_zone(letter_typed):
						word_zone_letters[get_number_letters_typed()].update_letter(letter_typed)
		# backspace should move the tile from the word into storage, or the saved zone if no space
		elif event.keycode == BACKSPACE:
			var number_of_letters_typed : int = get_number_letters_typed()
			var letter_zone_free_spot : int = find_free_spot_in_letter_zone()
			var save_zone_free_spot : int = find_free_spot_in_save_zone()
			if number_of_letters_typed > 0 and letter_zone_free_spot > -1:
				letter_zone_letters[letter_zone_free_spot].update_letter(word_zone_letters[number_of_letters_typed - 1].get_letter())
				word_zone_letters[number_of_letters_typed - 1].update_letter("-")
			elif number_of_letters_typed > 0 and save_zone_free_spot > -1:
				save_zone_letters[save_zone_free_spot].update_letter(word_zone_letters[number_of_letters_typed - 1].get_letter())
				word_zone_letters[number_of_letters_typed - 1].update_letter("-")


func _ready() -> void:
	EventBus.connect("start_scavenging", _on_start_scavenging)
	EventBus.connect("stop_scavenging", _on_stop_scavenging)
	
	visible = false
	for tile in word_zone.get_children():
		word_zone_letters.append(tile)
	for tile in letter_zone.get_children():
		letter_zone_letters.append(tile)
	for tile in save_zone.get_children():
		save_zone_letters.append(tile)
