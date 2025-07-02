extends HTTPRequest
class_name Asset

const RESOURCES_URL = "https://resources.download.minecraft.net/"

@export var assets_folder: String = "user://assets"

@export var endpoint: String
@export var hash: String
@export var size: String

var callback: Callable

func _init(data: Dictionary = {}, assets_folder: String = "user://"):
	self.assets_folder = assets_folder
	
	if data.is_empty():
		return
	
	hash = data.get("hash")
	endpoint = hash.substr(0, 2) + "/" + hash
	download_file = assets_folder.path_join("objects").path_join(endpoint)
	
	name = hash

func _ready() -> void:
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
		print_debug("Asset at %s downloaded" % get_url())
	callback.call()

func get_url() -> String:
	return RESOURCES_URL.path_join(endpoint)
