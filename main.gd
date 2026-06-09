extends Control

@onready var mc_launcher: MCProfileLauncher = $MCProfileLauncher
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	HTTPClientPool.task_queued.connect(
		func():
			progress_bar.max_value = max(1, HTTPClientPool.total_to_download)
	)
	HTTPClientPool.task_completed.connect(
		func():
			progress_bar.value = HTTPClientPool.total_downloaded
	)
	
	await mc_launcher.install()
	mc_launcher.launch()
