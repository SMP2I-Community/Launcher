extends Assets

func get_minecraft_folder() -> String:
	var path := ""
	match OS.get_name():
		"Windows":
			path = ProjectSettings.globalize_path("user://").get_base_dir().path_join(".minecraft")
		"Linux":
			path = OS.get_environment("HOME").path_join(".minecraft")
	
	return path

func install(asset_index: AssetIndex):
	var minecraft_assets_folder := get_minecraft_folder().path_join("assets")
	if DirAccess.dir_exists_absolute(minecraft_assets_folder):
		assets_folder = minecraft_assets_folder
	
	super.install(asset_index)
