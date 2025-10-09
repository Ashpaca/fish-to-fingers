extends Node
## Global signals

@warning_ignore_start("unused_signal")
signal state_changed
signal begin_start_server
signal begin_join_server
signal connect_camera_to(node : Node3D, offset : Vector3)
signal letter_typed(key_code : int)
signal go_to_node(node : TextNode)
signal start_fishing_at_node(node : FishingNode)
signal stop_fishing
signal stop_reeling
signal update_player_rotation_goal(angle : float)
signal tried_to_lure(letter : String, from_position : Vector3)
signal start_reeling_fish(fish : Fish)
signal peer_fishing_rod_state(fish_position : Vector3)
signal my_fishing_rod_state(fish_position : Vector3)
signal start_helping_fish(fish : Fish)
signal stop_spawning_regular_fish(water_group : String)
signal start_scavenging
signal stop_scavenging
signal tutorial_complete
signal tutorial_failed
signal inventory_changed
signal fillet_held_fish
