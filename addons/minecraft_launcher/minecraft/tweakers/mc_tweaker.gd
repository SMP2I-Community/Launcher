extends Resource
class_name MCTweaker

const NATIVES_DIR = "user://natives" #TODO: native folder must be set here only
const LIBRARIES_DIR = "user://libraries" #TODO: same here

const VERSION_MANIFEST_V2_URL = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
const VERSIONS_FOLDER = "versions"

@export var minecraft_version: StringName = "1.20.6"

var data := {}
var complementary_data := {}

var libraries := {}

var mc_libraries: MCLibraries

var client_jar_path: String = "" # Filled when download_client_jar is called

func get_version_data(minecraft_folder: String, version_id: StringName) -> Dictionary:
	var version_file = minecraft_folder.path_join(VERSIONS_FOLDER).path_join("%s.json" % version_id)
	DirAccess.make_dir_absolute(version_file.get_base_dir())
	
	if FileAccess.file_exists(version_file):
		var f := FileAccess.open(version_file, FileAccess.READ)
		var json := JSON.new()
		var err = json.parse(f.get_as_text())
		
		if err == OK:
			return json.data
	
	
	# if there is any issues, let's try to download the file again
	print_debug("Download version file for minecraft %s on %s" % [version_id, VERSION_MANIFEST_V2_URL])
	var versions = (await Utils.downloader.do_get(VERSION_MANIFEST_V2_URL)).json()
	assert(versions != null, "versions is null?")
	
	if not versions.is_empty():
		for v in versions["versions"]:
			if v["id"] == version_id:
				print_debug("Version found")
				var data = (await Utils.downloader.do_get(v["url"])).json()
				var f := FileAccess.open(version_file, FileAccess.WRITE)
				f.store_string(JSON.stringify(data))
				f.close()
				return data
	
	return {}

func get_complementary_version_data(version_id: StringName):
	return {}

func setup(minecraft_folder: String, java_path: String):
	data = await get_version_data(minecraft_folder, minecraft_version)
	complementary_data = await get_complementary_version_data(minecraft_version)
	if data.is_empty():
		push_error("No data for minecraft")
	if complementary_data.is_empty():
		push_warning("No complementary data: no mods")
	
	var libraries_data: Array = data.get("libraries", [])
	libraries_data.append_array(complementary_data.get("libraries", []))
	
	if libraries_data.is_empty():
		push_error("No data for libraries")
	
	for library_data in libraries_data:
		var lib = MCLibrary.new(library_data)
		libraries[lib.name] = lib

func download_libraries(target_folder: String):
	for lib in libraries.values():
		await (lib as MCLibrary).download_artifact(target_folder)
func download_natives(target_folder: String):
	for lib in libraries.values():
		await (lib as MCLibrary).download_native(target_folder)


func get_libraries():
	var paths: Array[String] = []
	for lib in libraries.values():
		var lib_path = (lib as MCLibrary).artifact_path
		var is_native = "native" in lib_path
		if lib_path != "":
			paths.append(ProjectSettings.globalize_path(lib_path))
	
	if client_jar_path != "":
		# Client jar is a library too
		paths.append(client_jar_path)
	return paths

func get_jvm() -> Array:
	var args = []
	for arg in data["arguments"]["jvm"]:
		var value = format_jvm_arg(arg)
		if value is String:  # If value is in a correct format
			args.append(value)
	
	return args

func format_jvm_arg(arg):
	var value = arg
	if arg is Dictionary and arg.has("rules"):
		var rule_respected = false
		
		for rule_d in arg["rules"]:
			var rule = MCRule.new(rule_d)
			rule_respected = rule_respected or rule.check_rule()
		
		if rule_respected:
			value = arg["value"]
		
	if value is String:
		#if "=" in value and "-D" in value:
			#value = value.replace("-D", '-D"').replace("=", '"=') # Powershell don't like =
		
		var separator: String = ":"
		if Utils.get_os_type() == Utils.OS_TYPE.WINDOWS:
			separator = ";"
		
		value = value.replace("${natives_directory}", ProjectSettings.globalize_path(NATIVES_DIR))
		value = value.replace("${launcher_name}", "SMP2I") #TODO: Variable
		value = value.replace("${launcher_version}", "1.0.0") #TODO: Variable
		value = value.replace("${library_directory}", ProjectSettings.globalize_path(LIBRARIES_DIR))
		value = value.replace("${classpath_separator}", separator)
		
		if value == "${classpath}":
			var libraries = get_libraries()
			value = separator.join(libraries)
	
	return value

func get_game_args():
	#["arguments"]["game"]
	return []

func get_main_class():
	return data["mainClass"]
func download_client_jar(versions_folder: String):
	var path = ProjectSettings.globalize_path(versions_folder.path_join("%s.jar") % minecraft_version)
	
	var client = data["downloads"]["client"]
	var url: String = client.get("url", "")
	var sha1: String = client.get("sha1", "")
	
	await Utils.download_file(url, path, sha1)
	
	client_jar_path = path
	return path

func get_assets():
	return MCAssets.new(data["assetIndex"])

func is_ready():
	return true
