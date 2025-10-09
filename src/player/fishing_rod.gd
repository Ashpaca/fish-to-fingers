extends Node3D

const LINE_THICKNESS : float = 0.01
const LINE_SEGMENTS : int = 6
const ROD : bool = true
const LINE : bool = false

@onready var fishing_line_starting_point: Node3D = $FishingLineStartingPoint
@onready var fishing_line: Node3D = $FishingLine
@onready var fishing_line_mesh: MeshInstance3D = $FishingLine/FishingLineMesh
@onready var join_catch_visual: Sprite3D = $FishingLineStartingPoint/JoinCatchVisual

var line_mesh_resource : CylinderMesh

func set_up_fishing_line(fish_position : Vector3) -> void:
	fishing_line.global_position = (fishing_line_starting_point.global_position + fish_position) / 2
	fishing_line.look_at(fish_position)
	line_mesh_resource.height = (fishing_line_starting_point.global_position - fish_position).length()

func _on_update_peers_rod(fish_position : Vector3) -> void:
	if is_multiplayer_authority(): return
	set_up_fishing_line(fish_position)


func _on_update_my_rod(fish_position : Vector3) -> void:
	if not is_multiplayer_authority(): return
	set_up_fishing_line(fish_position)


func _on_display_rod(_node : FishingNode) -> void:
	if is_multiplayer_authority():
		visible = true
		rpc("update_peer_visability", ROD, true)


func _on_stop_fishing() -> void:
	if is_multiplayer_authority():
		visible = false
		rpc("update_peer_visability", ROD, false)


func _on_stop_reeling() -> void:
	if is_multiplayer_authority():
		fishing_line.visible = false
		rpc("update_peer_visability", LINE, false)


func _on_start_reeling(_fish : Fish) -> void:
	if is_multiplayer_authority():
		fishing_line.visible = true
		rpc("update_peer_visability", LINE, true)


@rpc("any_peer", "call_remote")
func update_peer_visability(rod_or_line : bool, show_or_hide : bool) -> void:
	if rod_or_line == ROD:
		visible = show_or_hide
	else:
		fishing_line.visible = show_or_hide


func _process(_delta: float) -> void:
	if not GameState.is_playing(): return
	if not is_multiplayer_authority():
		join_catch_visual.visible = FishState.can_join_catch


func _ready() -> void:
	EventBus.peer_fishing_rod_state.connect(_on_update_peers_rod)
	EventBus.my_fishing_rod_state.connect(_on_update_my_rod)
	EventBus.start_fishing_at_node.connect(_on_display_rod)
	EventBus.stop_fishing.connect(_on_stop_fishing)
	EventBus.stop_reeling.connect(_on_stop_reeling)
	EventBus.start_reeling_fish.connect(_on_start_reeling)
	
	visible = false
	fishing_line.visible = false
	line_mesh_resource = CylinderMesh.new()
	line_mesh_resource.top_radius = LINE_THICKNESS
	line_mesh_resource.bottom_radius = LINE_THICKNESS
	line_mesh_resource.radial_segments = LINE_SEGMENTS
	fishing_line_mesh.mesh = line_mesh_resource
