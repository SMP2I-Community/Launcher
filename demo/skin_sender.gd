extends Node

@onready var skin_github_files: GithubFiles = $SkinGithubFiles
@onready var capes_github_files: GithubFiles = $CapesGithubFiles

func _ready() -> void:
	#ProfileManager.cape_updated.connect(_on_cape_updated)
	#ProfileManager.skin_updated.connect(_on_skin_updated)
	pass

func _on_cape_updated():
	var cape_path := ProfileManager.profile.cape_path
	var player_name := ProfileManager.get_player_name()
	capes_github_files.send_file(cape_path, "capes/%s.png" % player_name, "bot_%s" % player_name, "Update cape")

func _on_skin_updated():
	var skin_path := ProfileManager.profile.skin_path
	var player_name := ProfileManager.get_player_name()
	skin_github_files.send_file(skin_path, "skins/%s.png" % player_name, "bot_%s" % player_name, "Update skin")
