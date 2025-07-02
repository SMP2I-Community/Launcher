extends Resource
class_name JavaExecutor

@export var options: Array[String] = []

@export var open_console := false

func _init(options: Array[String] = []) -> void:
	self.options = options

func as_arguments() -> PackedStringArray:
	return PackedStringArray(options)
