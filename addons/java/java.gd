extends Progressor
class_name Java

signal on_execute

const INSTALLED_PROGRESS_VALUE := 250

#region Download Section
@export var installation_folder: String

@export_group("Download URLs")
@export var linux_download_url: String
@export var linux_executable_path := "bin/java"
@export var linux_unzipped_folder: String = ""
@export var windows_download_url: String
@export var windows_executable_path := "bin/java.exe"
@export var windows_unzipped_folder := ""
@export var macos_download_url: String = ""
@export var macos_executable_path := "Contents/Home/bin/java"
@export var macos_unzipped_folder: String = ""

var http_request: HTTPRequest
var extractor: Extractor

var is_installing := false
# Variable used when we try to execute and java isn't installed
var must_execute_in := false
var must_execute: JavaExecutor
var must_callback: Callable

func _ready() -> void:
	_init_http_request()
	_init_extractor()

func _init_http_request():
	http_request = HTTPRequest.new()
	http_request.request_completed.connect(_on_downloaded)
	http_request.accept_gzip = true
	http_request.use_threads = true
	add_child(http_request)

func _init_extractor():
	extractor = Extractor.new()
	extractor.extracted.connect(_on_extracted)

func is_installed() -> bool:
	if not FileAccess.file_exists(get_executable()):
		return false
	
	var test_executor := JavaExecutor.new()
	return _create_process(test_executor) != -1

func install():
	if is_installing:
		return # No need to download again
	
	is_installing = true
	
	if download(get_download_url()) != OK:
		push_error("An error occurred in the download request")
		is_installing = false

func get_download_url() -> String:
	var url: String = ""
	
	match OS.get_name():
		"Windows":
			url = windows_download_url
		"macOS":
			url = macos_download_url
		"Linux":
			url = linux_download_url
	
	return url

func get_download_file() -> String:
	var url := get_download_url()
	return installation_folder.path_join(url.get_file())

func download(url: String) -> int:
	assert(not url.is_empty(), "Download url is empty")
	
	var download_file = get_download_file()
	DirAccess.make_dir_recursive_absolute(download_file.get_base_dir())
	
	http_request.download_file = download_file
	return http_request.request(url, PackedStringArray(), HTTPClient.METHOD_GET, "")

func _on_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
		download(get_download_url())
		return
	
	assert(result == HTTPRequest.RESULT_SUCCESS, "Request failed: %s" % result)
	
	extractor.extract(get_download_file())

func _on_extracted(files: Array[String]):
	is_installing = false
	
	print_debug("Java installed")
	_progress = INSTALLED_PROGRESS_VALUE
	if must_execute != null:
		# We don't want to enter a loop where is_installed return false and java is downloaded again
		_execute(must_execute, must_callback)
#endregion

var thread: Thread

func get_local_executable_path() -> String:
	var path: String = ""
	match OS.get_name():
		"Windows":
			path = windows_executable_path
		"macOS":
			path = macos_executable_path
		"Linux":
			path = linux_executable_path
	
	return path

func get_unzipped_folder() -> String:
	var path: String = ""
	
	match OS.get_name():
		"Windows":
			path = windows_unzipped_folder
		"macOS":
			path = macos_unzipped_folder
		"Linux":
			path = linux_unzipped_folder
	
	if path.is_empty():
		path = get_download_url().get_file().get_basename()
	
	return path

func get_executable() -> String:
	var url := get_download_url()
	var path := installation_folder.path_join(get_unzipped_folder()).path_join(get_local_executable_path())
	return ProjectSettings.globalize_path(path)


func execute(executor: JavaExecutor, callback: Callable = Callable()):
	if not is_installed():
		must_execute = executor
		must_callback = callback
		must_execute_in = false
		install()
	else:
		_progress = INSTALLED_PROGRESS_VALUE
		_execute(executor, callback)

func execute_in(path: String, executor: JavaExecutor, callback := Callable()):
	if not is_installed():
		must_execute = executor
		must_callback = callback
		must_execute_in = true
		install()
	else:
		_progress = INSTALLED_PROGRESS_VALUE
		_execute_in(path, executor, callback)

func _create_process(executor: JavaExecutor, callback: Callable = Callable()) -> int:
	var executable: String = get_executable()
	return OS.create_process(executable, executor.as_arguments(), executor.open_console)

func _execute(executor: JavaExecutor, callback: Callable = Callable()):
	var executable: String = get_executable()
	
	thread = Thread.new()
	thread.start(_execute_thread.bind(executable, executor, callback))

func _execute_in(path: String, executor: JavaExecutor, callback := Callable()):
	var executable: String = get_executable()
	
	thread = Thread.new()
	thread.start(_execute_in_thread.bind(path, executable, executor, callback))

func _execute_thread(executable: String, executor: JavaExecutor, callback: Callable):
	var output = []
	
	on_execute.emit.call_deferred()
	
	var exit_code: int = OS.execute(executable, executor.as_arguments(), output, false, executor.open_console)
	
	callback.call_deferred(exit_code, output)

func _execute_in_thread(path: String, executable: String, executor: JavaExecutor, callback: Callable):
	var global_path := ProjectSettings.globalize_path(path)
	
	var cmd_path: String
	var cmd_file: FileAccess
	if Utils.get_os_type() == Utils.OS_TYPE.LINUX:
		cmd_path = global_path.path_join("execute_cmd.sh")
		cmd_file = FileAccess.open(cmd_path, FileAccess.WRITE)
		
		var permissions: int = (
			FileAccess.UNIX_EXECUTE_OWNER
			| FileAccess.UNIX_READ_OWNER
			| FileAccess.UNIX_WRITE_OWNER
			| FileAccess.UNIX_EXECUTE_GROUP
			| FileAccess.UNIX_READ_GROUP
			| FileAccess.UNIX_READ_OTHER
			| FileAccess.UNIX_EXECUTE_OTHER
		)
		
		FileAccess.set_unix_permissions(cmd_path, permissions)
	elif Utils.get_os_type() == Utils.OS_TYPE.WINDOWS:
		cmd_path = global_path.path_join(".execute_cmd.bat")
		cmd_file = FileAccess.open(cmd_path, FileAccess.WRITE)
	
	assert(cmd_file, "cmd_file is null")
	
	cmd_file.store_line("cd %s && %s %s" % [global_path, executable, " ".join(executor.as_arguments())])
	cmd_file.close()
	
	on_execute.emit.call_deferred()
	
	var output = []
	var exit_code: int = OS.execute(cmd_path, [], output, false, executor.open_console)
	
	callback.call_deferred(exit_code, output)
