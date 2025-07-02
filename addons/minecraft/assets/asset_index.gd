extends Resource
class_name AssetIndex

var data: Dictionary

func _init(data: Dictionary = {}) -> void:
	self.data = data

func get_id():
	return data.get("id", -1)
func get_sha1():
	return data.get("sha1", "")
func get_size():
	return data.get("size", -1)
func get_total_size():
	return data.get("totalSize", -1)
func get_url():
	return data.get("url", "")
