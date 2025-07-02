extends MinecraftTweaker
class_name ForgeTweaker

@export var forge_version: String = "1.20.1-forge-47.4.0"
@export var installation_folder: String = "user://"

var forge_version_data: Dictionary = {}

func get_forge_version_path() -> String:
	return installation_folder.path_join("versions/%s/%s.json" % [forge_version, forge_version])

func get_forge_data() -> Dictionary:
	if not forge_version_data.is_empty():
		return forge_version_data
	
	var version_path: String = get_forge_version_path()
	var forge_version_file := FileAccess.open(version_path, FileAccess.READ)
	forge_version_data = JSON.parse_string(forge_version_file.get_as_text())
	return forge_version_data

func get_game_args() -> MCGameArgs:
	var game_args := super.get_game_args()
	
	game_args.complementaries = get_forge_data().get("arguments", {}).get("game", [])
	
	return game_args

func get_jvm_args() -> ForgeJVMArgs:
	var jvm_args := ForgeJVMArgs.new()
	jvm_args.natives_directory = natives_folder
	jvm_args.libraries_folder = libraries_folder
	
	var forge_jvm = get_forge_data().get("arguments", {}).get("jvm", [])
	
	var separator: String = ":"
	if Utils.get_os_type() == Utils.OS_TYPE.WINDOWS:
		separator = ";"
	
	var formatted_forge_jvm = []
	for jvm: String in forge_jvm:
		var formatted_jvm = jvm.replace(
			"${version_name}", forge_version
		).replace(
			"${library_directory}", ProjectSettings.globalize_path(libraries.libraries_folder)
		).replace(
			"${classpath_separator}", separator
		)
		formatted_forge_jvm.append(formatted_jvm)
	
	jvm_args.complementaries = formatted_forge_jvm
	jvm_args.forge_version_data = forge_version_data
	jvm_args.client_path = client.download_file
	
	return jvm_args

func get_main_class():
	return get_forge_data().get("mainClass")
