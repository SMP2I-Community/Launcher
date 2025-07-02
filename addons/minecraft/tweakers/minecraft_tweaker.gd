extends Progressor
class_name MinecraftTweaker

signal installed

const VERSION_MANIFEST_V2_URL = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

@export var game_dir := "user://"
@export var versions_folder: String = "user://versions"

@export var natives_folder: String = "user://natives"
@export var libraries_folder: String = "user://libraries"

@export var assets: Assets
var assets_start_time: float = 0.0
var assets_end_time: float = 0.0
var assets_must_check := true

@export var libraries: Libraries

@export var client: Client

@export var version := "1.20.1"

var version_data: Dictionary = {}

var requester: Requests

func _ready() -> void:
	_init_requester()

func _init_requester():
	requester = Requests.new()
	add_child(requester)


func install():
	print("Start installation of the tweaker")
	version_data = await get_version_data()
	
	await install_assets()
	print("assets installed")
	await install_libraries()
	print("libraries installed")
	await install_client()
	
	installed.emit()

func get_progress():
	return assets.get_progress() + libraries.get_progress()

func _process(delta: float) -> void:
	if assets_must_check:
		check_assets_progress()

func check_assets_progress():
	if not assets.has_finished():
		return
	
	assets_end_time = Time.get_unix_time_from_system()
	var total_time: float = assets_end_time-assets_start_time
	if total_time < 5:
		return
	
	assets_must_check = false
	print("Total time to download assets: %.2fs" % [total_time])

func get_version_data() -> Dictionary:
	var version_file = versions_folder.path_join("%s.json" % version)
	DirAccess.make_dir_absolute(version_file.get_base_dir())
	
	if FileAccess.file_exists(version_file):
		var f := FileAccess.open(version_file, FileAccess.READ)
		var json := JSON.new()
		var err = json.parse(f.get_as_text())
		
		if err == OK:
			return json.data
	
	# if there is any issues, let's try to download the file again
	print_debug("Download version file for minecraft %s on %s" % [version, VERSION_MANIFEST_V2_URL])
	var versions = (await requester.do_get(VERSION_MANIFEST_V2_URL)).json()
	assert(versions != null, "versions is null?")
	
	if not versions.is_empty():
		for v in versions["versions"]:
			if v["id"] == version:
				print_debug("Version found")
				var data = (await requester.do_get(v["url"])).json()
				var f := FileAccess.open(version_file, FileAccess.WRITE)
				f.store_string(JSON.stringify(data))
				f.close()
				return data
	
	return {}

func get_game_args() -> MCGameArgs:
	var game_args := MCGameArgs.new()
	game_args.version = version
	game_args.game_dir = ProjectSettings.globalize_path(game_dir)
	game_args.assets_dir = ProjectSettings.globalize_path(assets.assets_folder)
	
	game_args.asset_index = version_data["assets"]
	return game_args

func get_jvm_args() -> MCJVMArgs:
	var jvm_args := MCJVMArgs.new()
	jvm_args.natives_directory = natives_folder
	jvm_args.libraries_folder = libraries_folder
	return jvm_args

func install_assets():
	assert(assets != null, "No assets node")
	
	var index = AssetIndex.new(version_data["assetIndex"])
	
	assets_start_time = Time.get_unix_time_from_system()
	assets.install(index)
	await assets.installed

func install_libraries():
	assert(libraries != null, "No libraries node")
	
	libraries.install(version_data["libraries"])
	await libraries.installed

func install_client():
	await client.install(version_data["downloads"]["client"]["url"])

func get_main_class():
	return version_data.get("mainClass")
