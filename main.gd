extends Node

func _ready() -> void:
	SceneLoader.change_online_scene(
		"https://raw.githubusercontent.com/SMP2I-Community/LauncherUI/refs/heads/main/ui.pck",
		"user://ui.pck",
		"res://ui/main.tscn",
		"res://ui/main.tscn"
	)
