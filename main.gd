extends Control

const MODPACKS_URL: String = "https://raw.githubusercontent.com/SMP2I-Community/Modpacks/refs/heads/data/index.json"

#@onready var mc_launcher: MCProfileLauncher = $MCProfileLauncher
@onready var mc_launcher: MCLauncher = $MCLauncher
@onready var progress_bar: ProgressBar = $ProgressBar

@onready var version_option_button: OptionButton = $HBoxContainer/VersionOptionButton

var modpack_versions: DownloadTask
var modpacks: Array[Dictionary] = []

func _ready() -> void:
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

	#
	#await mc_launcher.install()
	#mc_launcher.launch(OfflineAuthenticator.new())


func _on_launch_button_pressed() -> void:
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
	
	profile.version = mc_version
	profile.modloader = modloader
	
	profile.authenticator = OfflineAuthenticator.new("Dev")
	
	await mc_launcher._install(profile)
	
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
