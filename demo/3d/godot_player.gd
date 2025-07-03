extends Node3D
class_name GodotPlayer

var player_mat: StandardMaterial3D
var cape_mat: StandardMaterial3D

@onready var player_animations: AnimationPlayer = $PlayerAnimations
@onready var skeleton_3d: Skeleton3D = $Armature/Skeleton3D

@onready var cape_mesh: MeshInstance3D = $cape/Cape

@onready var slim: Node3D = $Armature/Skeleton3D/Slim
@onready var wide: Node3D = $Armature/Skeleton3D/Wide

@export var skin: Texture2D : set = set_skin
@export var cape: Texture2D : set = set_cape
@export var hide_cape_if_empty := true

func _ready() -> void:
	player_mat = preload("res://demo/assets/materials/player_godot.tres").duplicate(true)
	cape_mat = preload("res://demo/assets/materials/cape.tres").duplicate(true)
	
	set_skin(skin)
	set_cape(cape)
	
	var body_meshs = skeleton_3d.find_children("*", "MeshInstance3D")
	for mesh: MeshInstance3D in body_meshs:
		mesh.set_surface_override_material(0, player_mat)
	
	cape_mesh.set_surface_override_material(0, cape_mat)

func set_skin(value: Texture2D):
	skin = value
	if player_mat:
		player_mat.albedo_texture = value
	
	if value:
		var img = value.get_image()
		
		print_debug("Skin is " + ("wide" if img.get_pixel(55, 20).a == 1.0 else "small"))
		if slim:
			slim.visible = img.get_pixel(55, 20).a != 1.0
		if wide:
			wide.visible = img.get_pixel(55, 20).a == 1.0

func set_cape(value: Texture2D):
	cape = value
	if cape_mat:
		cape_mat.albedo_texture = value
	
	if cape_mesh != null and hide_cape_if_empty:
		cape_mesh.visible = value != null
