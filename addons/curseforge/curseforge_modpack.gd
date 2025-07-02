extends Node
class_name CurseforgeModPack

signal mods_installed

@export_file("*.json") var manifest_path: String
@export var installation_folder: String = "user://mods"

var thread: Thread

func install():
	print_debug("Start mod installation")
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	var manifest = JSON.parse_string(manifest_file.get_as_text())
	
	for file in manifest.get("files", []):
		var mod_id = file["projectID"]
		var file_id = file["fileID"]
	
		var mod = CurseforgeMod.new()
		mod.name = str(mod_id)
		mod.mod_id = mod_id
		mod.file_id = file_id
		mod.installation_folder = installation_folder
		mod.installed.connect(_on_mod_installed.bind(mod))
		
		add_child(mod)
		
	for mod: CurseforgeMod in get_children():
		mod.download()

func _on_mod_installed(mod: CurseforgeMod):
	remove_child(mod)
	mod.queue_free()
	if get_child_count() == 0:
		mods_installed.emit()
