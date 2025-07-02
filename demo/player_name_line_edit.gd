extends LineEdit

@onready var warning_texture: TextureRect = $WarningTexture

func _ready() -> void:
	warning_texture.visible = text.is_empty()

func _set(property: StringName, value: Variant) -> bool:
	if property == "text":
		warning_texture.visible = value.is_empty()
	return false


func _on_text_changed(new_text: String) -> void:
	warning_texture.visible = new_text.is_empty()
