extends Control

const MODPACKS_URL: String = "https://raw.githubusercontent.com/SMP2I-Community/Modpacks/refs/heads/data/index.json"

@onready var mc_launcher: MCLauncher = $MCLauncher
@onready var progress_bar: ProgressBar = $ProgressBar

@onready var ram_label: Label = $RamContainer/RamLabel
@onready var username_line_edit: LineEdit = $UsernameLineEdit
@onready var error_label: Label = $ErrorLabel
@onready var ram_slider: HSlider = $RamContainer/RamSlider

@onready var version_option_button: OptionButton = $HBoxContainer/VersionOptionButton

var modpack_versions: DownloadTask
var modpacks: Array[Dictionary] = []

const CONFIG_PATH = "user://config.cfg"
var config := ConfigFile.new()

func _ready() -> void:
	var err = config.load(CONFIG_PATH)
	if err == OK:
		username_line_edit.text = config.get_value("settings", "name", "")
		ram_slider.value = config.get_value("settings", "ram", 4)
	
	_on_ram_slider_value_changed(ram_slider.value)
	modpack_versions = DownloadTask.new()
	modpack_versions.url = MODPACKS_URL
	modpack_versions.completed.connect(_on_versions_task_completed)
	
	HTTPClientPool.download(modpack_versions)

func _on_versions_task_completed(response: TaskResponse) -> void:
	var data: Dictionary = response.json()
	modpacks.assign(data.modpacks)
	
	for i in range(modpacks.size()):
		var modpack_info: Dictionary = modpacks[i]
		version_option_button.add_item(modpack_info.name, i)
	version_option_button.select(0)
	_setup_progress_bar()

func _setup_progress_bar() -> void:
	HTTPClientPool.task_queued.connect(
		func():
			progress_bar.max_value = max(1, HTTPClientPool.total_to_download)
	)
	HTTPClientPool.task_completed.connect(
		func():
			progress_bar.value = HTTPClientPool.total_downloaded
	)


func _on_launch_button_pressed() -> void:
	if username_line_edit.text.is_empty():
		error_label.text = "T'as oublié de mettre ton pseudo..."
		return
	
	var player_name = username_line_edit.text
	var ram_amount = int(ram_slider.value)
	
	config.set_value("settings", "name", player_name)
	config.set_value("settings", "ram", ram_amount)
	config.save(CONFIG_PATH)
	
	var idx: int = version_option_button.selected
	if idx < 0: return
	var modpack = modpacks[idx]
	
	var profile := MCProfile.new()
	profile.name = modpack.name
	
	var mc_version := MCVersion.new()
	mc_version.id = modpack.minecraft_version
	
	var modloader: ModLoader
	if modpack.has("modloader"):
		var modloader_id: String = modpack.modloader
		if modloader_id.begins_with("neoforge"):
			modloader = NeoforgeLoader.new()
			modloader.version = modloader_id.split("-")[1]
	
	profile.jvm_args = ["-Xmx%dG" % ram_amount, "-Xms2G"]
	profile.version = mc_version
	profile.modloader = modloader
	
	profile.authenticator = OfflineAuthenticator.new(player_name)
	
	Log.info("Starting installation")
	await mc_launcher._install(profile)
	Log.info("Installation finished")
	
	var files_url: String = modpack.files_url
	var files_task := DownloadTask.new()
	files_task.url = files_url
	
	var files: Dictionary = (await HTTPClientPool.download(files_task).wait()).json()
	var old_files_data: Dictionary = {}
	
	var old_files_path = profile.game_directory.path_join("modpacks/%s" % modpack.id)
	if not FileAccess.file_exists(old_files_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(old_files_path.get_base_dir())
	
	if FileAccess.file_exists(old_files_path):
		var old_files_file = FileAccess.open(old_files_path, FileAccess.READ)
		old_files_data = old_files_file.get_var(false)
	
	await update_modpack_installation(profile, old_files_data, files)
	var files_data = FileAccess.open(old_files_path, FileAccess.WRITE)
	files_data.store_var(files, false)
	
	mc_launcher._launch(profile, profile.authenticator)

func update_modpack_installation(profile: MCProfile, previous_data: Dictionary, new_data: Dictionary):
	var file_tasks: Array[DownloadTask] = []
	
	var files_to_remove: Array[String] = []
	
	for file_rel_path: String in previous_data:
		var file_info: Dictionary = new_data[file_rel_path]
		var file_sha1 = file_info.sha1
		if file_rel_path in new_data:
			if new_data[file_rel_path].sha1 == file_sha1:
				# Même version, pas besoin de s'en occuper, si ce n'est pas la même version, le fichier sera réécrit
				new_data.erase(file_rel_path)
		else:
			files_to_remove.append(file_rel_path)
	
	if files_to_remove.is_empty():
		Log.debug("Nothing to remove")
	
	for file_rel_path in files_to_remove:
		var file_path: String = profile.game_directory.path_join(file_rel_path)
		Log.info("Remove file '%s'" % file_path)
		if DirAccess.remove_absolute(file_path) != OK:
			Log.error("Failed to remove file '%s'" % file_path)
	
	if new_data.is_empty():
		Log.info("Nothing to update")
	else:
		Log.debug("Data to install: {}".format(new_data))
	
	for file_rel_path: String in new_data:
		Log.debug(file_rel_path)
		var file_path: String = profile.game_directory.path_join(file_rel_path)
		var file_info: Dictionary = new_data[file_rel_path]
		var file_url = file_info.url
		var file_size = file_info.size
		var file_sha1 = file_info.sha1
		
		DirAccess.make_dir_recursive_absolute(file_path.get_base_dir())
		var file_task := DownloadTask.new()
		file_task.url = file_url
		file_task.size = file_size
		file_task.sha1 = file_sha1
		file_task.destination = file_path
		HTTPClientPool.download(file_task)
		file_tasks.append(file_task)
	
	await DownloadTask.wait_all(file_tasks)


func _on_ram_slider_value_changed(value: float) -> void:
	ram_label.text = "Ram: %dGo" % value
