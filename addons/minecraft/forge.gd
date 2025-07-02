extends Progressor
class_name Forge

signal installed

const INSTALLED_CHECKER_PATH := "user://.forge_installed"

const INSTALLED_PROGRESS_VALUE := 100

@export var java: Java
@export_file var installer: String

@export var installation_folder := "user://"

func install():
	_create_profile()
	_copy_installer()
	_execute_installer()

func _create_profile():
	var profile = FileAccess.open(installation_folder.path_join("launcher_profiles.json"), FileAccess.WRITE)
	profile.store_string(JSON.stringify({}))

func _get_installer_path():
	return installation_folder.path_join(installer.get_file())

func _copy_installer():
	DirAccess.make_dir_recursive_absolute(installation_folder)
	var err = DirAccess.copy_absolute(installer, _get_installer_path())
	assert(err == OK, "Error while copying installer: %s" % err)

func _execute_installer():
	if FileAccess.file_exists(INSTALLED_CHECKER_PATH):
		print_debug("Forge already installed")
		send_install_infos()
		return
	
	var executor := JavaExecutor.new(["-jar", global(_get_installer_path()), "--installClient", global(installation_folder)])
	java.execute(executor, _on_executed)

func _on_executed(exit_code: int, output: Array):
	assert(exit_code == 0, "Failed to install forge (exit code: %s)" % exit_code)
	print_debug("Forge installed at %s" % global(installation_folder))
	
	var installed_checker_file := FileAccess.open(INSTALLED_CHECKER_PATH, FileAccess.WRITE)
	installed_checker_file.store_line("OUI forge a été installé, MAIS SI TU SUPPRIME UN SEUL FICHIER, BAH TU VAS TOUT NIQUER, alors touche à rien")
	send_install_infos()

func send_install_infos():
	_progress = INSTALLED_PROGRESS_VALUE
	installed.emit()

func global(path: String):
	return ProjectSettings.globalize_path(path)
