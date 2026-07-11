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
	var file_tasks: Array[DownloadTask] = []
	
	for file_rel_path: String in files:
		var file_path: String = profile.game_directory.path_join(file_rel_path)
		var file_info: Dictionary = files[file_rel_path]
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
	mc_launcher._launch(profile, profile.authenticator)


func _on_ram_slider_value_changed(value: float) -> void:
	ram_label.text = "Ram: %sGo" % value
