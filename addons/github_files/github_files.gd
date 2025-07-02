extends HTTPRequest
class_name GithubFiles

@export var github_owner: String
@export var github_repository: String

func _ready() -> void:
	request_completed.connect(_on_request_completed)

func send_file(path: String, to: String, author := "bot", message := "Add file"):
	var sha := await get_old_file_sha(to)
	var content = FileAccess.get_file_as_bytes(path)
	
	var headers := [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer %s" % GithubAPI.get_key(),
	]
	
	var data = {
		"message": message,
		"committer": {
			"name": author,
			"email": get_mail(author)
		},
		"content": Marshalls.raw_to_base64(content),
		"sha": sha
	}
	
	request(get_url(to), headers, HTTPClient.METHOD_PUT, JSON.stringify(data))

func get_url(to: String):
	return "https://api.github.com/repos/%s/%s/contents/%s" % [github_owner, github_repository, to]

func get_mail(author: String):
	return "%s@github.com" % author

func get_old_file_sha(to: String) -> String:
	request(get_url(to))
	var results = await request_completed
	assert(results[0] == HTTPRequest.RESULT_SUCCESS, "failed to get the sha of the old file")
	
	var body: PackedByteArray = results[3]
	var data: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	return data.get("sha", "")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	printt(result, response_code, JSON.parse_string(body.get_string_from_utf8()).get("message", "ok"))
