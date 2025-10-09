class_name ScavengeLetterTile extends Sprite2D

@onready var letter_box: RichTextLabel = $LetterBox

var empty_texture : Texture2D = preload("res://assets/sprites/Scavenge/scavenge_slot.png")
var tile_texture : Texture2D = preload("res://assets/sprites/Scavenge/scavenge_tile.png")
var letter : String

func update_letter(new_letter : String) -> void:
	letter = new_letter
	if letter == "-":
		letter_box.text = ""
		texture = empty_texture
	else:
		letter_box.text = "[font_size=32][color=NAVY_BLUE]" + letter.to_upper() + "[/color][/font_size]"
		texture = tile_texture


func get_letter() -> String:
	return letter


func _ready() -> void:
	letter = "-"
	letter_box.text = ""
	texture = empty_texture
