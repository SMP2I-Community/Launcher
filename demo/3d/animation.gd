extends Node3D

@export var skins: Array[Texture2D] = []

@onready var godot_player: GodotPlayer = $GodotPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var animations: Array[Callable] = [
	walk_fast,
	staring,
	walk_upside_down,
	sliding,
	rotating
]

func _ready() -> void:
	select_skin()
	select_animation()
	#rotating()
	sitting()

func select_skin():
	var skin: Texture = skins.pick_random()
	godot_player.skin = skin


func select_animation():
	var anim: Callable = animations.pick_random()
	anim.call()

func walk_fast():
	animation_player.play("MovePlayer")
	godot_player.player_animations.play("WalkFast")

func walk_upside_down():
	animation_player.play("MovePlayerUpsideDown")
	godot_player.player_animations.play("WalkFast")

func staring():
	animation_player.play("Staring")
	godot_player.player_animations.play("RESET")

func sliding():
	animation_player.play("Sliding")
	godot_player.player_animations.play("Sliding")

func rotating():
	animation_player.play("Rotating")
	godot_player.player_animations.play("RESET")

func sitting():
	animation_player.play("RotatingLow")
	godot_player.player_animations.play("Sitting")
