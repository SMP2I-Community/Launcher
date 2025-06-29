extends SubViewportContainer

signal change_cape_request

@onready var player: Node3D = $SubViewport/player

var start_pos: Vector2
var start_rotation: float = 0.0
var should_rotate: bool = false

@export var rotation_force: float = 0.05
@export var rotation_speed: float = 0.002

func _ready() -> void:
	player.rotation_speed = rotation_speed

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.is_pressed():
			player.can_animate = true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			start_rotation = player.get_camera_rotation()
			player.set_camera_rotation(start_rotation)
			start_pos = event.position
		
		should_rotate = event.pressed
		player.can_animate = not event.pressed
	if event is InputEventMouseMotion and should_rotate:
		player.set_camera_rotation(start_rotation - (event.position.x - start_pos.x) * rotation_force)


func _on_player_change_cape_request() -> void:
	change_cape_request.emit() # Because i'm lazy af
