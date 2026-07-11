extends Node

func _ready() -> void:
	if OS.is_debug_build():
		SceneLoader.change_scene("res://ui/main.tscn")
	else:
		SceneLoader.change_online_scene(
			"https://raw.githubusercontent.com/SMP2I-Community/LauncherUI/refs/heads/main/ui.pck",
			"user://ui.pck",
			"res://ui/main.tscn",
			"res://ui/main.tscn"
		)
