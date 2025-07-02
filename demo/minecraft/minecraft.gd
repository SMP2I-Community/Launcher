extends Progressor

signal on_minecraft_run

@onready var java: Java = $Java
@onready var releases: Progressor = $Releases

@onready var tweaker: MinecraftTweaker = $ForgeTweaker
@onready var minecaft_runner: MinecaftRunner = $MinecaftRunner


var installing := false

var releases_installed := false
var minecraft_installed := false

var want_to_run := false

func get_progress() -> int:
	return tweaker.get_progress() + java.get_progress() + releases.get_progress()

func install():
	installing = true
	releases.install()

func run():
	if can_run():
		_on_minecraft_can_run()
	else:
		want_to_run = true

func can_run():
	return releases_installed and minecraft_installed

func _on_releases_installed() -> void:
	releases_installed = true
	check_want_to_run()
	
	#WARNING: Tweaker need to be installed here because it needs forge version file, downloaded by a release
	tweaker.install()

func _on_tweaker_installed() -> void:
	minecraft_installed = true
	check_want_to_run()

func check_want_to_run():
	if can_run() and want_to_run:
		_on_minecraft_can_run()

func _on_minecraft_can_run():
	print_debug("Launch minecraft")
	minecaft_runner.run()


func _on_minecaft_runner_on_run() -> void:
	on_minecraft_run.emit()
