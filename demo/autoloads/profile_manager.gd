extends Node

signal skin_updated
signal cape_updated

const SKIN_PATH := "user://skin.png"
const CAPE_PATH := "user://cape.png"

const MINECRAFT_UUID = "https://api.mojang.com/users/profiles/minecraft/%s"
const MINECRAFT_PROFILE = "https://sessionserver.mojang.com/session/minecraft/profile/%s"
const UNKOWN_SKIN = preload("res://demo/assets/textures/skins/unkown.png")

@export var minecraft_folder: String = "user://"

var profile: MCProfile = MCProfile.load_profile(minecraft_folder)

@onready var downloader: Requests = $Requests
@onready var skin_download_timer: Timer = $SkinDownloadTimer

@onready var skin_github_files: GithubFiles = $SkinGithubFiles
var skin_sha: String
@onready var capes_github_files: GithubFiles = $CapesGithubFiles
var cape_sha: String

func set_player_name(value: String):
	profile.player_name = value if value.replace(" ", "") != "" else "Player"
	profile.save_profile()
	
	if not FileAccess.file_exists(SKIN_PATH):
		skin_download_timer.start()

func set_skin(path):
	DirAccess.copy_absolute(path, SKIN_PATH)
	skin_updated.emit()

func set_cape(path):
	DirAccess.copy_absolute(path, CAPE_PATH)
	cape_updated.emit()

func get_player_name() -> String:
	return profile.player_name

func get_skin() -> Texture2D:
	if FileAccess.file_exists(SKIN_PATH):
		var image = Image.load_from_file(SKIN_PATH)
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
		file.save(SKIN_PATH)
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
		file.save(CAPE_PATH)
	return true

func get_cape():
	if FileAccess.file_exists(CAPE_PATH):
		var image = Image.load_from_file(CAPE_PATH)
		var texture = ImageTexture.create_from_image(image)
		return texture
	return null

func download_minecraft_skin() -> bool:
	if FileAccess.file_exists(SKIN_PATH):
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
		await downloader.do_file(skin_data["textures"]["SKIN"]["url"], SKIN_PATH)
		print_debug("Minecraft skin downloaded")
		return true
	
	print_debug("No idk")
	return false

func send_to_github():
	_send_skin(get_player_name())
	_send_cape(get_player_name())

func _send_skin(player_name: String):
	skin_github_files.send_file(SKIN_PATH, "skins/%s.png" % player_name, skin_sha, "bot_%s" % player_name, "Update skin")

func _send_cape(player_name: String):
	capes_github_files.send_file(CAPE_PATH, "capes/%s.png" % player_name, cape_sha, "bot_%s" % player_name, "Update cape")


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
