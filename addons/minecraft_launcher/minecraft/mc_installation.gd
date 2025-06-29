@tool
extends Node
class_name MCInstallation

signal version_file_loaded

signal new_file_downloaded(files_downloaded: int, files_to_download: int)

signal libraries_downloaded
signal assets_downloaded
signal client_downloaded
signal java_downloaded

signal on_run

const LIBRARIES_FOLDER = "libraries"
const NATIVES_FOLDER = "natives"
const ASSETS_FOLDER = "assets"
const VERSIONS_FOLDER = "versions"
const RUNTIME_FOLDER = "runtime"

@export var progress_bar: ProgressBar
@export var mass_downloads: MassDownloads

@export var java_manager: JavaManager
@export var launcher_name := "GoCraft"
@export var launcher_version := "1.0.0"

@export_dir var overrides_folder: String = ""

@export var tweaker: MCTweaker
@export var mods: Array[MCMod] = []

@export_category("Folders")
@export var minecraft_folder = "user://"
@export var game_folder = "user://"

@export_category("Modifications")
@export var mod_loader := MINECRAFT_MOD_LOADER.VANILLA
@export_placeholder("x.x.x") var fabric_loader_version: String
@export var mod_list: Array[MinecraftMod] = []

@export_category("MC Version")
@export var mc_version_type := MINECRAFT_VERSION_TYPE.OFFICIAL:
	set(v):
		mc_version_type = v
		notify_property_list_changed()
var mc_version_id: String = ""
var mc_version_file: String = ""

var version_data: Dictionary = {}

enum MINECRAFT_MOD_LOADER {
	VANILLA,
	FORGE,
	FABRIC
}

enum MINECRAFT_VERSION_TYPE {
	OFFICIAL,
	PERSONAL
}

var downloader: Requests

var files_downloaded: int = 0
var files_to_download: int = 1000

var mc_runner = MCRunner.new()
var need_to_wait = false

var thread := Thread.new()

@export var TOTAL_TO_DOWNLOAD := 5000

func _get_property_list():
	var properties = []
	var version_file_usage = PROPERTY_USAGE_NO_EDITOR
	var mc_version_id_usage = PROPERTY_USAGE_NO_EDITOR
	var mod_list_usage = PROPERTY_USAGE_NO_EDITOR
	
	if mc_version_type == MINECRAFT_VERSION_TYPE.OFFICIAL:
		mc_version_id_usage = PROPERTY_USAGE_DEFAULT
	elif mc_version_type == MINECRAFT_VERSION_TYPE.PERSONAL:
		version_file_usage = PROPERTY_USAGE_DEFAULT
	
	if mod_loader in [MINECRAFT_MOD_LOADER.FORGE, MINECRAFT_MOD_LOADER.FABRIC]:
		mod_list_usage = PROPERTY_USAGE_DEFAULT
	
	properties.append({
		"name": "mc_version_file",
		"type": TYPE_STRING,
		"usage": version_file_usage,
		"hint": PROPERTY_HINT_FILE
	})
	properties.append({
		"name": "mc_version_id",
		"type": TYPE_STRING,
		"usage": mc_version_id_usage,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "x.x.x"
	})
	
	return properties


func _ready() -> void:
	pass
	#await load_version_file()

func install_overrides():
	if overrides_folder == null or overrides_folder.replace(" ", "") == "":
		return
	var internal_overrides = DirAccess.open(overrides_folder)
	
	var folders_to_visit = [overrides_folder]
	
	if internal_overrides == null:
		print_verbose("Error while opening overrides folder")
		return
	
	while not folders_to_visit.is_empty():
		var current_folder = folders_to_visit.pop_front()
		var dir = DirAccess.open(current_folder)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				var path = current_folder.path_join(file_name)
				var local_path: String = path.replace(overrides_folder, "")
				if local_path[0] == "/":
					local_path = local_path.substr(1)
				var user_path = minecraft_folder.path_join(local_path)
				
				if dir.current_is_dir():
					folders_to_visit.append(path)
					dir.make_dir_absolute(user_path)
				else:
					if not FileAccess.file_exists(user_path):
						internal_overrides.copy(path, user_path)
				file_name = dir.get_next()
		else:
			print_verbose("Error opening %s" % current_folder)


func _on_new_file_downloaded(a, b):
	files_downloaded += 1
	new_file_downloaded.emit(files_downloaded, files_to_download)

func load_version_file() -> void:
	if mc_version_type == MINECRAFT_VERSION_TYPE.OFFICIAL:
		version_data = await MinecraftVersions.get_version_file(downloader, mc_version_id)
	elif mc_version_type == MINECRAFT_VERSION_TYPE.PERSONAL:
		var file = FileAccess.open(mc_version_file, FileAccess.READ)
		if file.get_error() != OK:
			print("error opening version_file")
			return
	
		var content = file.get_as_text()
		version_data = JSON.parse_string(content)
	print(version_data)
	version_file_loaded.emit()

func run(username: String) -> void:
	progress_bar.value = 0
	
	downloader = Requests.new()
	downloader.name = "Downloader"
	add_child(downloader)
	#await load_version_file()
	
	#-- DOWNLOAD JAVA
	var java_major_version = 17 #TODO: fix this, i'm forced to set manually 8
	var java_downloader: JavaDownloader = null
	if Utils.get_os_type() == Utils.OS_TYPE.LINUX:
		for linux_java_downloader in java_manager.linux_javas:
			if linux_java_downloader.java_major_version == str(java_major_version):
				java_downloader = linux_java_downloader
				break
	elif Utils.get_os_type() == Utils.OS_TYPE.WINDOWS:
		for windows_java_downloader in java_manager.windows_javas:
			if windows_java_downloader.java_major_version == str(java_major_version):
				java_downloader = windows_java_downloader
				break
	
	var java_folder_path = minecraft_folder.path_join(RUNTIME_FOLDER).path_join("java%s.zip" % java_major_version)
	var java_exe_path = ProjectSettings.globalize_path(java_folder_path.get_base_dir().path_join(java_downloader.exe_path))
	
	if OS.execute(java_exe_path, ["-version"]) != OK:
		# Issue when running java
		await java_downloader.download_java(minecraft_folder.path_join(RUNTIME_FOLDER))
		print("Java downloaded")
	java_downloaded.emit()
	await tweaker.setup(minecraft_folder, java_exe_path)
	
	print("Libs")
	await tweaker.download_libraries(minecraft_folder.path_join(LIBRARIES_FOLDER))
	
	print("Natives")
	await tweaker.download_natives(minecraft_folder.path_join(NATIVES_FOLDER))
	#var artifacts = tweaker.get_libraries()
	#print("%s artifacts" % len(artifacts))
	
	libraries_downloaded.emit()
	
	var mc_assets: MCAssets = tweaker.get_assets()
	await mc_assets.mass_download_assets(mass_downloads, minecraft_folder.path_join(ASSETS_FOLDER))
	
	assets_downloaded.emit()
	
	#-- Download MODS
	for mod in mods:
		(mod as CFMod).get_file(downloader, minecraft_folder.path_join("mods"))
	print("mods downloaded")
	
	#-- DOWNLOAD CLIENT
	#var client_jar_path: String = 
	await tweaker.download_client_jar(minecraft_folder.path_join(VERSIONS_FOLDER))
	client_downloaded.emit()
	
	#TODO: this is not working
	var jvm_args := MCJVMArgs.new()
	jvm_args.natives_directory = ProjectSettings.globalize_path(minecraft_folder.path_join(NATIVES_FOLDER))
	jvm_args.launcher_name = launcher_name
	jvm_args.launcher_version = launcher_version
	jvm_args.xmx = "%sG" % Config.max_ram
	jvm_args.complementaries = tweaker.get_jvm()

	var game_args := MCGameArgs.new()
	game_args.username = username
	game_args.version = mc_version_id
	game_args.game_dir = ProjectSettings.globalize_path(game_folder)
	game_args.assets_dir = ProjectSettings.globalize_path(minecraft_folder.path_join(ASSETS_FOLDER))
	game_args.asset_index = mc_assets.get_id()
	game_args.width = Config.x_resolution
	game_args.height = Config.y_resolution
	game_args.complementaries = tweaker.get_game_args()
	
	mc_runner.game_args = game_args
	mc_runner.jvm_args = jvm_args
	
	mc_runner.tweaker = tweaker
	mc_runner.java_path = java_exe_path
	
	if not tweaker.is_ready() or not mass_downloads.is_empty():
		print_debug("Need to wait a little more...")
		need_to_wait = true
	else:
		print_debug("MC is running")
		mc_runner.run()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		progress_bar.value = mass_downloads.downloaded
		
		if need_to_wait and tweaker.is_ready() and mass_downloads.is_empty():
			print_debug("MC is running")
			need_to_wait = false
			mass_downloads.downloaded = progress_bar.max_value # we have downloaded everythings
			mc_runner.run()
			on_run.emit()
