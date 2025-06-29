extends Resource
class_name JavaDownloader

@export_placeholder("19") var java_major_version: String
@export_placeholder("https://example.com") var url: String
@export_placeholder("xx/bin/java") var exe_path: String
@export_placeholder("zip") var extension: String = "zip"
@export var sha1: String

func download_java(folder: String) -> String:
	var path = folder.path_join("java%s.%s" % [java_major_version, extension])
	
	printt(url, path, sha1)
	await Utils.download_file(url, path, sha1, false)
	await Utils.unzip_file(path, [], false)
	return path
 
