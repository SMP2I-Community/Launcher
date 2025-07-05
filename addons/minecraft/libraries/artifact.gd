extends ThreaderDownloadable
class_name Artifact

@export var url: String
@export var libraries_folder: String

var data: Dictionary

var callback: Callable

func _init(artifact_data: Dictionary, libraries_folder := "user://libraries") -> void:
	data = artifact_data
	self.libraries_folder = libraries_folder

func get_download_file() -> String:
	return libraries_folder.path_join(self.get_jar_path().get_file())

func get_jar_path() -> String:
	return self.data.get("path")
func get_url() -> String:
	return self.data.get("url")
func get_sha1() -> String:
	return self.data.get("sha1", "")
