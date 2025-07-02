extends Object
class_name CurseforgeAPI

const ENTRY = "https://api.curseforge.com"

const GET_FILE = "/v1/mods/{mod_id}/files/{file_id}"

static var key: String

static func init(key: String) -> void:
	CurseforgeAPI.key = key

static func get_file_url(mod_id: int, file_id: int) -> String:
	return ENTRY.path_join(GET_FILE.format({"mod_id": mod_id, "file_id": file_id}))

static func get_key() -> String:
	assert(not key.is_empty(), "Curseforge api key is empty")
	return key
