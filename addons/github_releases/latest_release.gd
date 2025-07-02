extends Progressor
class_name LatestRelease

signal installed(udpated: bool)

@export var owner_name: String
@export var repository: String
@export var to_folder: String = "user://"
@export var force_update := false
@export var delete_archive := true
@export var delete_older := true

@export var PROGRESS_INSTALLED_VALUE := 10

var requests: Requests
var http_request: HTTPRequest
var extractor: Extractor

var zip_file := ""
var tag_name := ""

func _ready() -> void:
	_init_requests()
	_init_http_request()
	_init_extractor()

func _init_requests():
	requests = Requests.new()
	add_child(requests)

func _init_http_request():
	http_request = HTTPRequest.new()
	http_request.request_completed.connect(_on_downloaded)
	http_request.accept_gzip = true
	http_request.use_threads = true
	add_child(http_request)

func _init_extractor():
	extractor = Extractor.new()
	extractor.extracted.connect(_on_extracted)

func get_url() -> StringName:
	return "https://api.github.com/repos/%s/%s/releases/latest" % [owner_name, repository]

func install():
	download_zipball()

func download_zipball():
	self.zip_file = to_folder.path_join("%s.zip" % repository)
	
	DirAccess.make_dir_recursive_absolute(to_folder)
	
	var response: Requests.Response = (await requests.do_get(get_url()))
	if response.result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
		push_error("TLS Handshake error, try again")
		return await download_zipball()
	
	var response_data = response.json()
	if response_data == null:
		push_error("Data is null, try again")
		return await download_zipball()
	
	var zipball_url: String = response_data.get("zipball_url", "")
	if zipball_url.is_empty():
		if response_data.has("message"):
			installed.emit(false)
		push_error("zipball url is empty\t%s" % response_data)
		return
	
	tag_name = response_data.get("tag_name", "")
	
	var tag_file := get_tag_file(to_folder, FileAccess.READ)
	if not must_update(tag_file):
		_progress = PROGRESS_INSTALLED_VALUE
		installed.emit(false)
		return
	if delete_older:
		remove_older(tag_file)
	
	http_request.download_file = zip_file
	http_request.request(zipball_url)

func must_update(tag_file: FileAccess):
	if tag_file == null:
		return true
	return tag_name != tag_file.get_line() or force_update

func remove_older(tag_file: FileAccess):
	if tag_file == null:
		return
	
	print_debug("New release found, removing older files")
	var old_path := tag_file.get_line()
	while not old_path.is_empty():
		if FileAccess.file_exists(old_path):
			DirAccess.remove_absolute(old_path)
		old_path = tag_file.get_line()

func get_tag_path(dir: String) -> String:
	return dir.path_join(".%s_repo_tag_name" % repository)

func get_tag_file(dir: String, flag: FileAccess.ModeFlags) -> FileAccess:
	return FileAccess.open(get_tag_path(dir), flag)

func _on_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
		download_zipball()
		return
	
	assert(result == HTTPRequest.RESULT_SUCCESS, "Request failed: %s" % result)
	
	extractor.extract(zip_file, [], true, 1)

func _on_extracted(files: Array[String]):
	var tag_file := get_tag_file(to_folder, FileAccess.WRITE)
	tag_file.store_line(tag_name)
	for file in files:
		tag_file.store_line(file)
	
	print("Latest release of %s is now installed at %s" % [repository, to_folder])
	_progress = PROGRESS_INSTALLED_VALUE
	if delete_archive:
		DirAccess.remove_absolute(zip_file)
	
	installed.emit(true)
