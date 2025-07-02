extends Node
class_name MassDownloads

@export var nb_of_requesters := 4

var requesters: Array[HTTPRequest] = []
var current_de: Array[DownloadElement] = []

var _queue: Array[DownloadElement] = []
var _retry_queue: Array[DownloadElement] = []

var downloaded := 0

func _ready() -> void:
	for i in range(nb_of_requesters):
		var hr := HTTPRequest.new()
		hr.use_threads = true
		hr.accept_gzip = true
		hr.request_completed.connect(_on_request_completed.bind(i))
		add_child(hr)
		requesters.append(hr)
	
	current_de.resize(nb_of_requesters)


func add_to_queue(url: String, path: String, sha1: String = ""):
	_queue.append(DownloadElement.new(url, path, sha1))

func _process(delta: float) -> void:
	ask_requesters()

func is_empty():
	return _queue.is_empty() and _retry_queue.is_empty()

func size():
	return _queue.size()

func ask_requesters():
	for id: int in range(requesters.size()):
		if start_download_by(id):
			break

func start_download_by(id: int) -> bool:
	var hr = requesters[id]
	if hr.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return false
	
	var de: DownloadElement = _queue.pop_front()
	var from_retry := false
	if de == null:
		from_retry = true
		de = _retry_queue.pop_front()
	
	if de == null:
		return false
	
	DirAccess.make_dir_recursive_absolute(de.path.get_base_dir())
	if file_exists(de.path, de.sha1):
		downloaded += 1
		return true
	
	hr.download_file = de.path
	current_de[id] = de
	var err := hr.request(de.url, PackedStringArray(), HTTPClient.METHOD_GET, "")
	#printt("Try donwload", de.url, de.path)
	if err != OK:
		print("Error while requesting: %s" % err)
		_queue.append(de)
	
	return true

func file_exists(path: String, sha1) -> bool:
	if FileAccess.file_exists(path):
		if sha1 == "":
			return true
		elif Utils.check_sha1(path, sha1):
			return true
	return false

class DownloadElement extends RefCounted:
	var url: String
	var path: String
	var sha1: String
	
	func _init(url: String, path: String, sha1: String = "") -> void:
		self.url = url
		self.path = path
		self.sha1 = sha1

func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray,
	id: int
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		#if from_retry:
		push_error("Error while downlaoding assets! %s" % result)
		#else:
			#_retry_queue.append(de)
	
	downloaded += 1
	if not start_download_by(id):
		print("Ya un pb")
