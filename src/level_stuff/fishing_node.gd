class_name FishingNode extends TextNode

const FISHING_NODE_DISTANCE : float = 4
const FISHING_NODE_PATH_LENGTH : float = 5

@export var camera_offset : Vector3 = Vector3(0, 3.4, 2.4)
@export var camera_angle : float = -PI/6

func _ready() -> void:
	super._ready()
	MAX_DISTANCE_TO_PLAYER = FISHING_NODE_DISTANCE
	MAX_PATH_LENGTH_TO_PLAYER = FISHING_NODE_PATH_LENGTH
	text_box.text = "start fishing"


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
