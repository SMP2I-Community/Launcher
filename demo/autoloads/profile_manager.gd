extends Node

signal skin_updated
signal cape_updated

const SKIN_PATH := "user://CustomSkinLoader/LocalSkin/skins/%s.png"
const CAPE_PATH := "user://CustomSkinLoader/LocalSkin/capes/%s.png"

const MINECRAFT_UUID = "https://api.mojang.com/users/profiles/minecraft/%s"
const MINECRAFT_PROFILE = "https://sessionserver.mojang.com/session/minecraft/profile/%s"
const UNKOWN_SKIN = preload("res://demo/assets/textures/skins/unkown.png")

@export var minecraft_folder: String = "user://"

var profile: MCProfile = MCProfile.load_profile(minecraft_folder)

@onready var downloader: Requests = $Requests
@onready var skin_download_timer: Timer = $SkinDownloadTimer

@onready var skin_github_files: GithubFiles = $SkinGithubFiles
var skin_sha: String
var is_mojang_skin: bool = false

@onready var capes_github_files: GithubFiles = $CapesGithubFiles
var cape_sha: String

func set_player_name(value: String):
	profile.player_name = value if value.replace(" ", "") != "" else "Player"
	profile.save_profile()
	
	if not FileAccess.file_exists(get_skin_path()):
		skin_download_timer.start()

func get_skin_path():
	return SKIN_PATH % get_player_name()

func get_cape_path():
	return CAPE_PATH % get_player_name()

func set_skin(path):
	DirAccess.copy_absolute(path, get_skin_path())
	skin_updated.emit()

func set_cape(path):
	DirAccess.copy_absolute(path, get_cape_path())
	cape_updated.emit()

func get_player_name() -> String:
	return profile.player_name

func get_skin() -> Texture2D:
	if FileAccess.file_exists(get_skin_path()):
		var image = Image.load_from_file(get_skin_path())
		var texture = ImageTexture.create_from_image(image)
		return texture
	return UNKOWN_SKIN

func download_skin():
	if await download_github_skin() or await download_minecraft_skin():
		skin_updated.emit()
	else:
		print_debug("Failed to download skin")

func download_github_skin(save := true) -> bool:
	var file: GithubFiles.GithubFileData = await skin_github_files.get_existing_file("skins/%s.png" % get_player_name())
	if file == null:
		return false
	
	skin_sha = file.sha
	if save:
		file.save(get_skin_path())
	return true

func download_cape():
	if await download_github_cape():
		cape_updated.emit()

func download_github_cape(save := true) -> bool:
	var file: GithubFiles.GithubFileData = await capes_github_files.get_existing_file("capes/%s.png" % get_player_name())
	if file == null:
		return false
	
	cape_sha = file.sha
	if save:
		file.save(get_cape_path())
		is_mojang_skin = false
	return true

func get_cape():
	if FileAccess.file_exists(get_cape_path()):
		var image = Image.load_from_file(get_cape_path())
		var texture = ImageTexture.create_from_image(image)
		return texture
	return null

func download_minecraft_skin() -> bool:
	if FileAccess.file_exists(get_skin_path()):
		return true
	
	var player_data = (await downloader.do_get(MINECRAFT_UUID % profile.player_name)).json()
	if player_data == null:
		print_debug("Can't download skin")
		return false
	
	if not player_data.has("id"):
		print_debug("No uuid")
		return false

	var player_uuid = player_data["id"]
	var encoded_skin_data = (await downloader.do_get(MINECRAFT_PROFILE % player_uuid)).json()
	if not encoded_skin_data.has("properties"):
		print_debug("No properties")
		return false

	var skin_data: Dictionary = {}
	for d in encoded_skin_data["properties"]:
		if d["name"] == "textures":
			var s_d = Marshalls.base64_to_utf8(d["value"])
			var json = JSON.new()
			json.parse(s_d)
			skin_data = json.data
			break
	
	if skin_data:
		await downloader.do_file(skin_data["textures"]["SKIN"]["url"], get_skin_path())
		print_debug("Minecraft skin downloaded")
		is_mojang_skin = true
		return true
	
	print_debug("No idk")
	return false

func send_to_github():
	_send_skin(get_player_name())
	_send_cape(get_player_name())

func _send_skin(player_name: String):
	if not FileAccess.file_exists(get_skin_path()):
		return
	if is_mojang_skin:
		return
	
	skin_github_files.send_file(get_skin_path(), "skins/%s.png" % player_name, skin_sha, "bot_%s" % player_name, "Update skin")

func _send_cape(player_name: String):
	if not FileAccess.file_exists(get_cape_path()):
		return
	capes_github_files.send_file(get_cape_path(), "capes/%s.png" % player_name, cape_sha, "bot_%s" % player_name, "Update cape")


func _on_skin_download_timer_timeout() -> void:
	await download_minecraft_skin()
	skin_updated.emit()


func _on_skin_github_files_wrong_sha() -> void:
	await download_github_skin(false) # Reload sha
	# Yeah it can create infinite loops, i don't care okay? (at least i put a call deferred
	_send_skin.call_deferred(get_player_name())

func _on_capes_github_files_wrong_sha() -> void:
	await download_github_cape(false)
	_send_cape.call_deferred(get_player_name())
