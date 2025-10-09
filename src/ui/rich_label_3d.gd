class_name RichLabel3D extends Sprite3D

@export var label_width : int
@export var label_height : int
@export var font_size : int
@export var outline_size : int
@export var text : String

@onready var sub_viewport: SubViewport = $SubViewport
@onready var rich_text_label: RichTextLabel = $SubViewport/RichTextLabel

var number_of_matching_letters : int = 0
var total_typed_letters : int = 0
var starting_letters_skipped : int = 0

func _process(_delta: float) -> void:
	setup_text()


func setup_text() -> void:
	rich_text_label.size = Vector2(label_width, label_height)
	sub_viewport.size = Vector2(label_width, label_height)
	var displayed_message = "[center]" + "[outline_size=" + str(outline_size) + "]" + "[font_size=" + str(font_size) + "]"
	
	for i in range(len(text)):
		if text[i] == "\\":
			displayed_message += "\n"
		elif i < starting_letters_skipped:
			displayed_message += "[color=web_gray]" + text[i] + "[/color]"
		elif i < number_of_matching_letters + starting_letters_skipped:
			displayed_message += "[color=white]" + text[i] + "[/color]"
		elif i < total_typed_letters + starting_letters_skipped:
			displayed_message += "[color=red]" + text[i] + "[/color]"
		else:
			displayed_message += "[color=web_gray]" + text[i] + "[/color]"
	
	displayed_message +=   "[/font_size]" + "[/outline_size]" + "[/center]"
	
	rich_text_label.text = displayed_message


func matched_letters(matched_count : int, total_count : int, skip_letters : int = 0) -> void:
	number_of_matching_letters = matched_count
	total_typed_letters = total_count
	starting_letters_skipped = skip_letters
