extends RefCounted
class_name Extractor

## files is empty when using tar
signal extracted(files: PackedStringArray)

var thread: Thread

func extract(path: String, exclude: Array[String] = [], use_thread = true, strip_components := 0):
	var extract_function: Callable
	if is_zip(path):
		extract_function = unzip
	if is_tar(path):
		extract_function = untar
	
	assert(not extract_function.is_null(), "Extract function is null")
	
	extract_function = extract_function.bind(path, exclude, strip_components)
	if use_thread:
		thread = Thread.new()
		thread.start(extract_function)
	else:
		extract_function.call()

func is_tar(path: String) -> bool:
	return path.ends_with("tar.gz") # hess

func is_zip(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	return file.get_buffer(4) == PackedByteArray([0x50, 0x4b, 0x03, 0x04])

func untar(path: String, exclude: Array[String] = [], strip_components: int = 0):
	strip_components += 1 # Because
	#TODO: exclude plzz
	var output = []
	var os_path := ProjectSettings.globalize_path(path)
	var os_dir := ProjectSettings.globalize_path(path.get_basename())
	
	DirAccess.make_dir_recursive_absolute(os_dir)
	
	OS.execute("tar", ["-xf", os_path, "-C", os_dir, "--strip-components=%s" % strip_components], output)
	_is_extracted.call_deferred(PackedStringArray())
	

func unzip(path: String, exclude: Array[String] = [], strip_components: int = 0):
	var reader := ZIPReader.new()
	var err = reader.open(path)
	assert(err == OK, "Failed to open zip file")
	
	var files = reader.get_files()
	
	var extract_files: Array[String] = []
	for zip_file in files:
		if zip_file.get_file() in exclude:
			continue
		
		var extracted_path = extract_file(reader, zip_file, path.get_base_dir(), strip_components)
		if not extracted_path.is_empty():
			extract_files.append(extracted_path)
	
	reader.close()
	_is_extracted.call_deferred(PackedStringArray(extract_files))

func extract_file(reader: ZIPReader, inner_path: String, outer_dst: String, strip_components: int = 0) -> String:
	if not reader.file_exists(inner_path):
		return ""
	
	var stripped_inner_path := inner_path
	if strip_components > 0:
		stripped_inner_path = inner_path.split("/", true, strip_components)[-1]
	var outer_path: String = outer_dst.path_join(stripped_inner_path)
	
	var is_folder: bool = inner_path.ends_with("/")
	if is_folder:
		return ""
	if FileAccess.file_exists(outer_path):
		DirAccess.remove_absolute(outer_path)
	
	var outer_folder = ProjectSettings.globalize_path(outer_path.get_base_dir())
	if not DirAccess.dir_exists_absolute(outer_folder):
		DirAccess.make_dir_recursive_absolute(outer_folder)
	
	var extracted_file = FileAccess.open(outer_path, FileAccess.WRITE)
	if extracted_file != null:
		var bytes := reader.read_file(inner_path, true)
		extracted_file.store_buffer(bytes)
		extracted_file.close()
		FileAccess.set_unix_permissions(outer_path, 511) #TODO: use custom build
	
	return outer_path

func _is_extracted(files: PackedStringArray):
	extracted.emit(files)
