extends Node3D

@export var water_body_group : String
@export var fish_types : Array[FishData]
@export var qte_letter_options : Array[String] = ["q","w","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","z","x","c","v","b","n","m"]

@onready var spawn_point: Node3D = $SpawnPoint
@onready var despawn_point: Node3D = $DespawnPoint
@onready var swim_zones: Node3D = $SwimZones

var fish_scene : PackedScene = load("res://src/fish/fish.tscn")
var schooler_scene : PackedScene = load("res://src/fish/schooler.tscn")
var swim_zone_dimensions : Array[Vector4]
var do_spawn_regualr_fish : bool = true
var do_spawn_schooler_fish : bool = false

# should these be exported
var spawn_timer : float = 0.0
var spawn_delay : float = 3.0
var swarm_spawn_delay : float = 0.8

func spawn_regular_fish(delta : float) -> void:
	spawn_timer += delta
	if spawn_timer > spawn_delay:
		spawn_timer = 0.0
		if len(qte_letter_options) < 1: return # We need to wait for a letter to be avaliable
		var new_fish : Fish = fish_scene.instantiate()
		#new_fish.name = str(new_fish.get_rid())
		add_child(new_fish, true)
		new_fish.qte_letter = qte_letter_options.pick_random()
		new_fish.fish_type = fish_types.pick_random()
		new_fish.global_position = spawn_point.global_position
		new_fish.water_body_im_in = water_body_group
		qte_letter_options.erase(new_fish.qte_letter)
		new_fish.fish_removed.connect(_on_fish_removed)
		
		for length in new_fish.fish_type.word_lengths:
			match length:
				3:
					new_fish.word_list.append(GameState.ALL_WORDS_LENGTH_3.pick_random())
				4:
					new_fish.word_list.append(GameState.ALL_WORDS_LENGTH_4.pick_random())
				5:
					new_fish.word_list.append(GameState.ALL_WORDS_LENGTH_5.pick_random())
				6:
					new_fish.word_list.append(GameState.ALL_WORDS_LENGTH_6.pick_random())
				7:
					new_fish.word_list.append(GameState.ALL_WORDS_LENGTH_7.pick_random())
				_:
					new_fish.word_list.append(GameState.ALL_WORDS_LENGTH_5.pick_random())
		
		for zone in swim_zone_dimensions:
			for _i in range(new_fish.fish_type.stops_per_swim_zone):
				var random_point : Vector3 = Vector3(zone.x + randf_range(-zone.z, zone.z), global_position.y, zone.y + randf_range(-zone.w, zone.w))
				new_fish.places_to_swim.append(random_point)
		new_fish.places_to_swim.append(despawn_point.global_position)
		
		new_fish.start_swimming()


func spawn_schooler_fish(delta : float) -> void:
	spawn_timer += delta
	if spawn_timer > swarm_spawn_delay:
		spawn_timer = 0.0
		var new_schooler : Schooler = schooler_scene.instantiate()
		add_child(new_schooler, true)
		new_schooler.fish_type = fish_types.pick_random()
		new_schooler.global_position = spawn_point.global_position
		match new_schooler.fish_type.word_lengths[0]: # should probably put a check on this for words that have already been used. Like letters for QTEs
			3:
				new_schooler.word_box.text = GameState.ALL_WORDS_LENGTH_3.pick_random()
			4:
				new_schooler.word_box.text = GameState.ALL_WORDS_LENGTH_4.pick_random()
			5:
				new_schooler.word_box.text = GameState.ALL_WORDS_LENGTH_5.pick_random()
			6:
				new_schooler.word_box.text = GameState.ALL_WORDS_LENGTH_6.pick_random()
			7:
				new_schooler.word_box.text = GameState.ALL_WORDS_LENGTH_7.pick_random()
			_:
				new_schooler.word_box.text = GameState.ALL_WORDS_LENGTH_5.pick_random()
		for zone in swim_zone_dimensions:
			new_schooler.places_to_swim.append(Vector3(zone.x, global_position.y, zone.y))
		new_schooler.places_to_swim.append(despawn_point.global_position)
		new_schooler.start_swimming()


func _on_fish_removed(used_letter : String) -> void:
	qte_letter_options.append(used_letter)


func _on_stop_spawning_regular_fish(group_name : String) -> void:
	if group_name == water_body_group:
		pass# do_spawn_regualr_fish = false need to set up something for sending these signals


func _ready() -> void:
	EventBus.stop_spawning_regular_fish.connect(_on_stop_spawning_regular_fish)
	for zone in swim_zones.get_children():
		var zone_collision : BoxShape3D = zone.get_child(0).shape
		swim_zone_dimensions.append(Vector4(zone.global_position.x, zone.global_position.z, zone_collision.size.x / 2, zone_collision.size.z / 2))


func _physics_process(delta: float) -> void:
	if not GameState.is_playing(): return
	if not multiplayer.is_server(): return
	if do_spawn_regualr_fish:
		spawn_regular_fish(delta)
	if do_spawn_schooler_fish:
		spawn_schooler_fish(delta)
	
	if Input.is_action_just_pressed("ui_down"): # for testing purposes
		if do_spawn_regualr_fish:
			EventBus.stop_spawning_regular_fish.emit(water_body_group)
			do_spawn_regualr_fish = false
			do_spawn_schooler_fish = true
		else:
			do_spawn_regualr_fish = true
			do_spawn_schooler_fish = false
