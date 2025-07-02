extends Resource
class_name MCJVMArgs

@export var launcher_name: String = "SMP2I"
@export var launcher_version: String = "1.0"
@export var libraries_folder: String
@export var natives_directory: String

@export var xms: String = "1G"
@export var xmx: String = "4G"

var complementaries: Array = []

func to_array() -> Array:
	var array: Array = complementaries.duplicate()
	
	array.append('"-Djava.library.path=%s"' % ProjectSettings.globalize_path(natives_directory))
	array.append('"-Dminecraft.launcher.brand=%s"' % launcher_name)
	array.append('"-Dminecraft.launcher.version=%s"' % launcher_version)
	array.append("-Xmx%s" % xmx)
	array.append("-Xms%s" % xms)
	
	var separator: String = ":"
	if Utils.get_os_type() == Utils.OS_TYPE.WINDOWS:
		separator = ";"
	array.append_array(["-cp", separator.join(get_libraries())])
	
	return array

func get_libraries() -> Array[String]:
	assert(not libraries_folder.is_empty(), "libraries_folder is empty")
	
	var dirs_path: Array[String] = [libraries_folder]
	var libraries: Array[String] = []
	
	while not dirs_path.is_empty():
		var dir_path: String = dirs_path.pop_front()
		var dir := DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					#WARNING: i don't think i need to search file recursively as i download all libraries in libraries, and forge
					# gives a string of all the paths
					#dirs_path.append(dir_path.path_join(file_name))
					pass
				elif is_library(file_name):
					var library_path: String = dir_path.path_join(file_name)
					libraries.append(ProjectSettings.globalize_path(library_path))
				file_name = dir.get_next()
		else:
			print("An error occurred when trying to access the path.")
	
	return libraries

func is_library(file_name: String) -> bool:
	return file_name.get_extension() == "jar"
