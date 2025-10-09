extends Node3D

const ROTATE_SPEED : float = 0.03

@onready var actual_camera: Camera3D = $ActualCamera
@onready var camera_ray: RayCast3D = $CameraRay

var current_offset : Vector3 = Vector3.ZERO
var rotateLeft : bool = false
var rotateRight : bool = false

func _on_connect_camera(node : Node3D, offset : Vector3, angle : float = -PI/6) -> void:
	reparent(node)
	position = Vector3.ZERO
	actual_camera.position = offset
	actual_camera.rotation.x = angle
	current_offset = offset


func _on_start_fishing(node : FishingNode) -> void:
	_on_connect_camera(node, node.camera_offset, node.camera_angle)


func _on_start_reeling(fish : Fish) -> void:
	_on_connect_camera(fish, Vector3.BACK * 1.5, 0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_left"):
		rotateLeft = true
	if event.is_action_pressed("rotate_right"):
		rotateRight = true
	if event.is_action_released("rotate_left") or event.is_action_released("rotate_right"):
		rotateLeft = false
		rotateRight = false


func _physics_process(_delta: float) -> void:
	if rotateLeft:
		rotate_y(ROTATE_SPEED)
	if rotateRight:
		rotate_y(-ROTATE_SPEED)
		
	camera_ray.target_position = current_offset - camera_ray.position
	if camera_ray.is_colliding():
		actual_camera.global_position = camera_ray.get_collision_point()
	else:
		actual_camera.position = current_offset

func _ready() -> void:
	EventBus.connect_camera_to.connect(_on_connect_camera)
	EventBus.start_fishing_at_node.connect(_on_start_fishing)
	EventBus.start_reeling_fish.connect(_on_start_reeling)
	EventBus.start_helping_fish.connect(_on_start_reeling)
