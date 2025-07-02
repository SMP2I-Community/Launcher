extends Progressor

signal installed

@onready var capes_release: LatestRelease = $CapesRelease
@onready var overrides_release: LatestRelease = $OverridesRelease

var capes_installed := false
var overrides_installed := false

func install():
	capes_release.install()
	overrides_release.install()

func get_progress():
	return capes_release.get_progress() + overrides_release.get_progress()

func check_installed():
	if is_installed():
		installed.emit()

func is_installed():
	return capes_installed and overrides_installed


func _on_capes_release_installed(_udpated: bool) -> void:
	capes_installed = true
	check_installed()


func _on_overrides_release_installed(_udpated: bool) -> void:
	overrides_installed = true
	check_installed()
