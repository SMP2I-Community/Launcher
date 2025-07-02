extends HTTPRequest
class_name Client

@export var download_folder: String = "user://"

func install(url: String):
	download_file = download_folder.path_join(url.get_file())
	
	request(url)
	var results = await request_completed
	if results[0] != HTTPRequest.RESULT_SUCCESS:
		push_error("Error while downloading client at %s" % url)
