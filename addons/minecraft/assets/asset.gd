extends ThreaderDownloadable
class_name Asset

const RESOURCES_URL = "https://resources.download.minecraft.net/"

@export var assets_folder: String = "user://assets"

@export var endpoint: String
@export var hash: String
@export var size: String

var callback: Callable

var download_file: String

func _init(data: Dictionary = {}, assets_folder: String = "user://"):
	self.assets_folder = assets_folder
	
	if data.is_empty():
		return
	
	hash = data.get("hash")
	endpoint = hash.substr(0, 2) + "/" + hash

func get_download_file() -> String:
	return assets_folder.path_join("objects").path_join(endpoint)

func get_url() -> String:
	return RESOURCES_URL.path_join(endpoint)
