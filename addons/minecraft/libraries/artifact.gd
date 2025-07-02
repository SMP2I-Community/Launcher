extends HTTPRequest
class_name Artifact

@export var url: String

var data: Dictionary

var callback: Callable

func _init(artifact_data: Dictionary, libraries_folder := "user://libraries") -> void:
	data = artifact_data
	
	download_file = libraries_folder.path_join(self.get_jar_path().get_file())

func _ready() -> void:
	name = get_jar_path().get_file()
	request_completed.connect(_on_request_completed)

func download(callback: Callable):
	self.callback = callback
	
	DirAccess.make_dir_recursive_absolute(download_file.get_base_dir())
	if FileAccess.file_exists(download_file):
		callback.call()
		return
	
	request.call_deferred(get_url())

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Error while downloading %s" % get_url())
	else:
		print_debug("Library at %s downloaded" % get_url())
	callback.call()

func get_jar_path() -> String:
	return self.data.get("path")
func get_url() -> String:
	return self.data.get("url")
func get_sha1() -> String:
	return self.data.get("sha1", "")
