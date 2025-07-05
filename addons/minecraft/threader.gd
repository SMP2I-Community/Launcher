extends Progressor
class_name Threader

signal finished

var thread: Thread

var http_request: HTTPRequest

var downloaded: int = 0

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)

func download(downloadable: ThreaderDownloadable, callback: Callable) -> void:
	if downloadable.get_download_file().is_empty() or downloadable.get_url().is_empty():
		push_error("Missing parameter for %s" % downloadable)
		return
	
	DirAccess.make_dir_recursive_absolute(downloadable.get_download_file().get_base_dir())
	if not FileAccess.file_exists(downloadable.get_download_file()):
		http_request.download_file = downloadable.get_download_file()
		http_request.request(downloadable.get_url())
		
		var results = await http_request.request_completed
		
		if results[0] != HTTPRequest.RESULT_SUCCESS:
			push_error("Error %s while downloading %s" % [results[0], downloadable.get_url()])
		else:
			print("%s - %s downloaded at %s" % [name, downloadable.get_url(), downloadable.get_download_file()])
	else:
		# A little wait else the launcher will freeze
		await get_tree().create_timer(0.01).timeout
	
	downloaded += 1
	
	callback.call_deferred()


func start(thread_callable: Callable):
	thread = Thread.new()
	thread.start(thread_callable)

func get_progress():
	return downloaded

func _exit_tree() -> void:
	if thread != null:
		thread.wait_to_finish()
