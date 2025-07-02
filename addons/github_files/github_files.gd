extends HTTPRequest
class_name GithubFiles

@export var github_owner: String
@export var github_repository: String

func _ready() -> void:
	request_completed.connect(_on_request_completed)

func get_headers() -> PackedStringArray:
	var headers := [
		"Accept: application/vnd.github+json",
		"Authorization: Bearer %s" % GithubAPI.get_key(),
	]
	return PackedStringArray(headers)

func send_file(path: String, to: String, sha: String = "", author := "bot", message := "Add file"):
	#var sha := await get_old_file_sha(to)
	var content = FileAccess.get_file_as_bytes(path)
	
	var data = {
		"message": message,
		"committer": {
			"name": author,
			"email": get_mail(author)
		},
		"content": Marshalls.raw_to_base64(content),
		"sha": sha
	}
	
	request(get_url(to), get_headers(), HTTPClient.METHOD_PUT, JSON.stringify(data))

func get_url(to: String):
	return "https://api.github.com/repos/%s/%s/contents/%s" % [github_owner, github_repository, to]

func get_mail(author: String):
	return "%s@github.com" % author

func get_existing_file(to: String) -> GithubFileData:
	request(get_url(to), get_headers())
	var results = await request_completed
	assert(results[0] == HTTPRequest.RESULT_SUCCESS, "Failed to download existing file")
	
	var body: PackedByteArray = results[3]
	var data: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	if not (data.has("content") and data.has("sha")):
		return null
	
	return GithubFileData.new(data["content"], data["sha"])

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	printt(result, response_code, JSON.parse_string(body.get_string_from_utf8()).get("message", "ok"))

class GithubFileData extends RefCounted:
	var sha: String
	## Content is in base64
	var content: String
	
	func _init(content: String, sha: String):
		self.content = content
		self.sha = sha
	
	func save(to: String):
		var buffer := Marshalls.base64_to_raw(content)
		var file = FileAccess.open(to, FileAccess.WRITE)
		file.store_buffer(buffer)
