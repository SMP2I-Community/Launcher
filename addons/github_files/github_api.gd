extends Object
class_name GithubAPI

static var key: String

static func init(key: String) -> void:
	GithubAPI.key = key

static func get_key() -> String:
	assert(not key.is_empty(), "Github api key is empty")
	return key
