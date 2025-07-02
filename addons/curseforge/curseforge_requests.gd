extends Requests
class_name CurseforgeRequests

func do(
		url: String,
		data := "",
		headers := PackedStringArray(),
		method := HTTPClient.METHOD_GET,
		download_file := ""
) -> Response:
	headers.append("x-api-key: %s" % CurseforgeAPI.get_key())
	return await super.do(url, data, headers, method, download_file)
