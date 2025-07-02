extends Node
class_name CurseforgeMod

signal installed

const GENERATED_URL: String = "https://mediafilez.forgecdn.net/files/%s/%s/%s"

@export var mod_id: int
@export var file_id: int
@export var installation_folder: String

var requester: CurseforgeRequests

func _ready() -> void:
	requester = CurseforgeRequests.new()
	add_child(requester)

func download():
	DirAccess.make_dir_recursive_absolute(installation_folder)
	
	var download_info := await _get_download_url()
	if download_info == null:
		push_error("Failed to get download's info for %s" % mod_id)
		return
	
	await requester.do_file(download_info.url, installation_folder.path_join(download_info.file_name))
	
	installed.emit()

func _get_download_url() -> DownloadInfo:
	var response = (await requester.do_get(CurseforgeAPI.get_file_url(mod_id, file_id)))
	if response.json() == null:
		push_error("Failed to download mod infos. Code: %s. Result: %s" % [response.code, response.result])
		return
	
	var data = response.json().get("data", {})
	
	var download_url = data.get("downloadUrl")
	var file_name = data.get("fileName")
	
	if download_url != null:
		return DownloadInfo.new(download_url, file_name)
	
	if file_name != null:
		return _generate_download_info(file_name)
	
	return null


## I'm not sure the generated url is really correct, so this function is used only when necessary
func _generate_download_info(file_name: String) -> DownloadInfo:
	var first_half = str(file_id).substr(0, 4)
	var second_half = str(file_id).substr(4).replace("0", "")
	return DownloadInfo.new(GENERATED_URL % [first_half, second_half, file_name], file_name)

class DownloadInfo extends RefCounted:
	var url: String
	var file_name: String
	
	func _init(url: String, file_name: String):
		self.url = url
		self.file_name = file_name
