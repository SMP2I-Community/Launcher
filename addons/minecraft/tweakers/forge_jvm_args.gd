extends MCJVMArgs
class_name ForgeJVMArgs

var forge_version_data: Dictionary
var client_path: String = ""

func get_libraries() -> Array[String]:
	var libraries := super.get_libraries()
	# On retire le client car sinon ça crash
	libraries.erase(ProjectSettings.globalize_path(client_path))
	
	for library_data: Dictionary in forge_version_data.get("libraries", {}):
		var path: String = library_data.get("downloads", {}).get("artifact", {}).get("path", "")
		if path.is_empty():
			push_error("path is empty for %s" % library_data)
			continue
		
		var godot_path := libraries_folder.path_join(path)
		var global_path := ProjectSettings.globalize_path(godot_path)
		
		libraries.append(global_path)
	
	return libraries
