extends Progressor
class_name Libraries

signal installed

@export var libraries_folder := "user://libraries"
@export var natives_folder := "user://natives"

var artifacts_number: int = 0

var libraries: Array[Library] = []

@onready var artifact_threader: Threader = $ArtifactThreader
#@onready var natives_threader: Threader = $NativesThreader

func install(libraries_list: Array):
	for library_data in libraries_list:
		var lib = Library.new(library_data, libraries_folder, natives_folder)
		libraries.append(lib)
	
	install_libraries()
	install_natives()

func install_libraries():
	artifact_threader.start(_download_libraries.bind(artifact_threader, libraries, libraries_folder))

func install_natives():
	for lib: Library in libraries:
		#print(lib.as_native())
		pass

func _download_libraries(threader: Threader, libraries: Array[Library], libraries_folder: String):
	var artifact: Artifact
	while artifact == null:
		var lib: Library = libraries.pop_front()
		if lib == null:
			print_debug("All artifacts of %s have been downloaded" % threader.name)
			threader.finished.emit()
			return
		
		artifact = lib.as_artifact()
	
	threader.download.call_deferred(artifact, _download_libraries.bind(threader, libraries, libraries_folder))

func _artifact_callback(threader: Threader, artifact: Artifact, artifacts: Array):
	if artifact != null:
		threader.remove_child.call_deferred(artifact)
		artifact.queue_free.call_deferred()
	
	var next_artifact = artifacts.pop_front()
	if not next_artifact is Artifact: #WARNING: because of the inner HTTPRequest
		next_artifact = artifacts.pop_front()
	
	if next_artifact == null:
		print_debug("All artifacts of %s have been downloaded" % threader.name)
		threader.finished.emit()
		return
	
	next_artifact.download.call_deferred(_artifact_callback.bind(threader, next_artifact, artifacts))

func get_progress() -> int:
	return artifacts_number - artifact_threader.get_child_count()


func _on_artifact_threader_finished() -> void:
	installed.emit()
